# frozen_string_literal: true

module Worldwide
  module Cldr
    # Marks the code that runs inside one Worldwide::Cldr.with_bundled_data block. The block closes
    # its scope when it returns. A closed scope stays active while the scope that was current when
    # its block started is active, so a thread or fiber that inherited it reads bundled data until
    # every block around the code that created it has returned, even if it outlives those blocks.
    # Closing is not synchronized with those threads: a lookup that one of them is making at that
    # moment may still read bundled data.
    class BundledDataScope
      # enclosing is the scope that was current when the block started, or nil.
      def initialize(enclosing = nil)
        @enclosing = enclosing
        @open = true
      end

      def active?
        @open || (!@enclosing.nil? && @enclosing.active?)
      end

      def close
        @open = false
      end

      # Fiber storage (Ruby 3.2 and later). Threads and fibers created inside the block inherit the scope,
      # so they read bundled data while it is active.
      module FiberStorage
        class << self
          def scope
            Fiber[:worldwide_bundled_data_scope]
          end

          def scope=(value)
            Fiber[:worldwide_bundled_data_scope] = value
          end
        end
      end

      # Fiber-local variables, for Rubies without fiber storage. Threads and fibers do not inherit them,
      # so threads and fibers created inside the block read the host's data.
      module FiberLocalStorage
        class << self
          def scope
            Thread.current[:worldwide_bundled_data_scope]
          end

          def scope=(value)
            Thread.current[:worldwide_bundled_data_scope] = value
          end
        end
      end

      STORAGE = Fiber.respond_to?(:[]) ? FiberStorage : FiberLocalStorage
    end
  end
end
