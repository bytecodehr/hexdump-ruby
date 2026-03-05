require 'json'
require 'net/http'
require 'uri'
require 'securerandom'

require_relative 'hexdump/configuration'
require_relative 'hexdump/transport'
require_relative 'hexdump/context'
require_relative 'hexdump/middleware'
require_relative 'hexdump/railtie' if defined?(Rails::Railtie)
require_relative 'hexdump/sidekiq' if defined?(Sidekiq)

module Hexdump
  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    def capture(exception, context: {})
      return unless configuration&.endpoint

      backtrace = exception.backtrace || []
      payload = {
        type: 'error',
        exception_class: exception.class.name,
        message: exception.message,
        backtrace: backtrace.first(50),
        context: Context.current.merge(context),
        environment: configuration.environment,
        git_sha: configuration.git_sha,
        hostname: Socket.gethostname,
        pid: Process.pid,
        occurred_at: Time.now.utc.iso8601(3)
      }

      Transport.enqueue(payload)
    end

    # Structured logging
    def log(level, message, **context)
      return unless configuration&.endpoint

      payload = {
        type: 'log',
        level: level.to_s,
        message: message,
        context: Context.current.merge(context),
        environment: configuration.environment,
        git_sha: configuration.git_sha,
        hostname: Socket.gethostname,
        pid: Process.pid,
        logged_at: Time.now.utc.iso8601(3)
      }

      Transport.enqueue(payload)
    end

    def debug(msg, **ctx) = log(:debug, msg, **ctx)
    def info(msg, **ctx)  = log(:info, msg, **ctx)
    def warn(msg, **ctx)  = log(:warn, msg, **ctx)
    def error(msg, **ctx) = log(:error, msg, **ctx)
    def fatal(msg, **ctx) = log(:fatal, msg, **ctx)

    # Set context for current request/thread
    def set_context(**ctx)
      Context.set(**ctx)
    end

    def clear_context
      Context.clear
    end
  end
end
