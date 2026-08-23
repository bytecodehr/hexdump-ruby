# frozen_string_literal: true

require "minitest/autorun"

module Rails
  class Railtie
    def self.initializer(*)
    end
  end
end

module ActiveSupport
  def self.on_load(*)
  end
end

require_relative "../lib/hexdump/railtie"

class ErrorSubscriberTest < Minitest::Test
  def setup
    Hexdump.captures = []
  end

  def test_accepts_and_captures_the_rails_error_source
    error = RuntimeError.new("boom")

    Hexdump::ErrorSubscriber.new.report(
      error,
      handled: false,
      severity: :error,
      context: {request_id: "req-123"},
      source: "application"
    )

    assert_equal [
      [error, {request_id: "req-123", handled: false, severity: :error, source: "application"}]
    ], Hexdump.captures
  end
end

module Hexdump
  class << self
    attr_accessor :captures

    def capture(error, context:)
      captures << [error, context]
    end
  end
end
