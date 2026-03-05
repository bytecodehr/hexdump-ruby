module Hexdump
  module Context
    THREAD_KEY = :hexdump_context

    class << self
      def current
        Thread.current[THREAD_KEY] || {}
      end

      def set(**ctx)
        Thread.current[THREAD_KEY] = current.merge(ctx)
      end

      def clear
        Thread.current[THREAD_KEY] = nil
      end
    end
  end
end
