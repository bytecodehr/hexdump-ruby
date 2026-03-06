# Hexdump Ruby Client

Ruby client gem for [Hexdump](https://github.com/bytecodehr/hexdump) — self-hosted error tracking and structured logging with local AI-powered grouping and analysis.

Zero runtime dependencies. Uses only Ruby stdlib (`net/http`, `json`).

## Installation

```ruby
# Gemfile
gem "hexdump", git: "https://github.com/bytecodehr/hexdump-ruby.git"
```

## Configuration

```ruby
# config/initializers/hexdump.rb
Hexdump.configure do |config|
  config.endpoint = "https://your-hexdump-server.example.com"
  config.api_key  = Rails.application.credentials.dig(:hexdump, :api_key)
  config.enabled  = Rails.env.production? || Rails.env.staging?
end
```

## What it does automatically

When loaded in a Rails app, Hexdump automatically:

- **Captures all unhandled exceptions** via Rack middleware (including controller errors, routing errors, etc.)
- **Logs every request** with controller, action, status, duration, and filtered params
- **Captures ActiveJob/Sidekiq errors** with job class, ID, queue, and arguments
- **Subscribes to `Rails.error`** for any errors reported via `Rails.error.handle` / `Rails.error.record`
- **Batches and sends** events in a background thread (non-blocking, never affects your app)

No configuration beyond the initializer is needed. No middleware to add manually.

## Manual usage

### Structured logging

```ruby
Hexdump.info("User signed up", user_id: user.id, plan: "pro")
Hexdump.warn("Rate limit approaching", ip: request.ip, count: 98)
Hexdump.error("Payment failed", user_id: user.id, amount: 49_99)
Hexdump.debug("Cache miss", key: "user:#{id}")
Hexdump.fatal("Database connection lost")
```

### Manual error capture

```ruby
begin
  risky_operation
rescue => e
  Hexdump.capture(e, context: { user_id: current_user.id })
  raise # or handle gracefully
end
```

### Request context

Context is automatically set per-request (request ID, IP, path, method, user agent). You can add custom context:

```ruby
Hexdump.set_context(user_id: current_user.id, account_id: current_account.id)
```

Context is thread-local and cleared automatically after each request.

## Transport

Events are queued in-memory and flushed in a background thread:

- **Batch size**: 50 events (configurable via `config.batch_size`)
- **Flush interval**: 5 seconds (configurable via `config.flush_interval`)
- **Max queue**: 1,000 events — drops new events if exceeded (configurable via `config.max_queue_size`)
- **Failure mode**: silent. Transport errors are swallowed and never affect your app.

## API

Events are sent to `POST /api/v1/ingest` on your Hexdump server with:

- Header: `X-Hexdump-Key: <your-api-key>`
- Body: JSON with `{ errors: [...], logs: [...] }`

## Requirements

- Ruby >= 3.0
- A running [Hexdump server](https://github.com/bytecodehr/hexdump)

## License

MIT
