# frozen_string_literal: true

module Worldwide
  module Cldr
    # Marks the code that runs inside one Worldwide::Cldr.with_bundled_data block.
    # The block closes its scope when it returns, so a thread or fiber that inherited
    # the scope stops reading bundled data at that point, even if it outlives the block.
    class BundledDataScope
      def initialize
        @active = true
      end

      def active?
        @active
      end

      def close
        @active = false
      end

      # Fiber storage (Ruby 3.2 and later). Threads and fibers created inside the block inherit the scope,
      # so they read bundled data until the block returns.
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

      # Fiber-local variables (Ruby 3.1, which has no fiber storage). Threads and fibers do not inherit them,
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
