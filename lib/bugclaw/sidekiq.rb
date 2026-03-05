module Hexdump
  module SidekiqPlugin
    class ErrorHandler
      def call(error, context = {})
        job = context[:job] || {}
        Hexdump.capture(error, context: {
                          job_class: job['class'],
                          job_id: job['jid'],
                          queue: job['queue'],
                          args: job['args']&.inspect&.slice(0, 500),
                          retry_count: job['retry_count']
                        })
      end
    end

    class ServerMiddleware
      def call(_worker, job, queue)
        Hexdump.set_context(
          job_class: job['class'],
          job_id: job['jid'],
          queue: queue
        )

        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        yield
        duration = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round(1)

        Hexdump.info('Job completed',
                     job_class: job['class'],
                     job_id: job['jid'],
                     queue: queue,
                     duration_ms: duration)
      rescue StandardError
        # Error is captured by ErrorHandler, just re-raise
        raise
      ensure
        Hexdump.clear_context
      end
    end
  end
end

# Auto-configure if Sidekiq is loaded
if defined?(Sidekiq)
  Sidekiq.configure_server do |config|
    config.error_handlers << Hexdump::SidekiqPlugin::ErrorHandler.new

    config.server_middleware do |chain|
      chain.add Hexdump::SidekiqPlugin::ServerMiddleware
    end
  end
end
