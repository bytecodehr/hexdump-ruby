module Hexdump
  module Transport
    @queue = Queue.new
    @mutex = Mutex.new
    @thread = nil

    class << self
      def enqueue(payload)
        return unless Hexdump.configuration&.enabled?
        return if @queue.size >= Hexdump.configuration.max_queue_size

        @queue.push(payload)
        ensure_thread_running
      end

      private

      def ensure_thread_running
        @mutex.synchronize do
          return if @thread&.alive?

          @thread = Thread.new { flush_loop }
          @thread.abort_on_exception = false
        end
      end

      def flush_loop
        buffer = []
        last_flush = Time.now

        loop do
          # Non-blocking pop with timeout
          event = begin
            @queue.pop(true)
          rescue StandardError
            nil
          end

          buffer << event if event

          should_flush = buffer.size >= Hexdump.configuration.batch_size ||
                         (buffer.any? && Time.now - last_flush >= Hexdump.configuration.flush_interval)

          if should_flush
            send_batch(buffer.dup)
            buffer.clear
            last_flush = Time.now
          end

          sleep(0.1) unless event
        rescue StandardError
          # Never crash the transport thread
          buffer.clear
          sleep(1)
        end
      end

      def send_batch(events)
        return if events.empty?

        config = Hexdump.configuration
        uri = URI("#{config.endpoint}/api/v1/ingest")

        errors = events.select { |e| e[:type] == 'error' }
        logs = events.select { |e| e[:type] == 'log' }

        payload = {}
        payload[:errors] = errors if errors.any?
        payload[:logs] = logs if logs.any?

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.open_timeout = 5
        http.read_timeout = 10

        req = Net::HTTP::Post.new(uri.path)
        req['Content-Type'] = 'application/json'
        req['X-Hexdump-Key'] = config.api_key
        req.body = JSON.generate(payload)

        http.request(req)
      rescue StandardError
        # Silently fail — never affect the host app
      end
    end
  end
end
