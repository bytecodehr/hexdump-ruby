module Hexdump
  class Railtie < Rails::Railtie
    initializer 'hexdump.middleware' do |app|
      app.middleware.insert_before(0, Hexdump::Middleware)
    end

    initializer 'hexdump.error_reporter' do
      Rails.error.subscribe(Hexdump::ErrorSubscriber.new) if defined?(ActiveSupport::ErrorReporter)
    end

    initializer 'hexdump.active_job' do
      ActiveSupport.on_load(:active_job) do
        ActiveJob::Base.around_perform do |job, block|
          Hexdump.set_context(
            job_class: job.class.name,
            job_id: job.job_id,
            queue: job.queue_name
          )
          block.call
        rescue StandardError => e
          Hexdump.capture(e, context: {
                            job_class: job.class.name,
                            job_id: job.job_id,
                            job_args: job.arguments.inspect.slice(0, 500)
                          })
          raise
        ensure
          Hexdump.clear_context
        end
      end
    end
  end

  class ErrorSubscriber
    def report(error, handled:, severity:, context: {})
      Hexdump.capture(error, context: context.merge(
        handled: handled,
        severity: severity
      ))
    end
  end
end
