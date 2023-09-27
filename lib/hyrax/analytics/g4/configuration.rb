module Hyrax
  module Analytics
    module G4
      class Configuration
        def initialize
          @metadata_coercers = {}
        end

        ##
        # Register a coercer for the given {Hyrax::CounterMetric}.
        #
        # @see G4::WorkMetadata
        #
        # @param key [#to_sym]
        # @param block [#call]
        def register_coercer(key:, &block)
          raise G4::Error, "Expected #{self.class}##{__method__} to receive a block." if block.empty?
          raise G4::Error, "Expected #{self.class}##{__method__} to receive a block with arity 1 got arity #{block.arity}." unless block.arity == 1

          @metadata_coercers[key.to_sym] = block
        end

        def metadata_coercer_for(key)
          @metadata_coercers.fetch(key) { method(:default_metadata_coercer) }
        end

        def default_metadata_coercer(value)
          Array.wrap(value).first
        end
      end
    end
  end
end
