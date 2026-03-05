module Hexdump
  class Configuration
    attr_accessor :endpoint, :api_key, :environment, :git_sha,
                  :flush_interval, :batch_size, :max_queue_size,
                  :enabled

    def initialize
      @endpoint = ENV['HEXDUMP_ENDPOINT']
      @api_key = ENV['HEXDUMP_API_KEY']
      @environment = ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
      @git_sha = ENV['GIT_SHA'] || ENV['HEROKU_SLUG_COMMIT'] || `git rev-parse --short HEAD 2>/dev/null`.strip
      @flush_interval = 5  # seconds
      @batch_size = 50     # flush after N events
      @max_queue_size = 1000 # drop events if queue exceeds this
      @enabled = true
    end

    def enabled?
      @enabled && @endpoint && @api_key
    end
  end
end
