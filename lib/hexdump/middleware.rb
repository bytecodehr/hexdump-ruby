module Hexdump
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      # Set request context
      request = Rack::Request.new(env)
      Hexdump.set_context(
        request_id: env['action_dispatch.request_id'] || env['HTTP_X_REQUEST_ID'],
        ip: request.ip,
        method: request.request_method,
        path: request.path,
        user_agent: request.user_agent&.slice(0, 200)
      )

      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      status, headers, body = @app.call(env)
      duration = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round(1)

      # Log request
      if defined?(Rails) && env['action_controller.instance']
        ctrl = env['action_controller.instance']
        Hexdump.info("#{request.request_method} #{request.path} → #{status}",
                     controller: ctrl.class.name,
                     action: ctrl.action_name,
                     status: status,
                     duration_ms: duration,
                     params: filtered_params(env))
      end

      [status, headers, body]
    rescue Exception => e
      Hexdump.capture(e, context: {
                        method: request&.request_method,
                        path: request&.path,
                        params: filtered_params(env)
                      })
      raise
    ensure
      Hexdump.clear_context
    end

    private

    def filtered_params(env)
      return {} unless env

      params = env['action_dispatch.request.parameters'] || {}
      params.except('controller', 'action', 'password', 'password_confirmation',
                    'secret', 'token', 'api_key', 'authenticity_token')
            .transform_values { |v| v.is_a?(String) && v.length > 200 ? "#{v[0..200]}..." : v }
            .slice(*params.keys.first(20)) # max 20 params
    rescue StandardError
      {}
    end
  end
end
