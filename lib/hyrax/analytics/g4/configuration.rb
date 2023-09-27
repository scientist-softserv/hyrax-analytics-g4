module Hyrax
  module Analytics
    module G4
      class Configuration
        def initialize
          @metadata_coercers = {}
          @attribute_names_to_solr_names = {
            work_id: :id,
            worktype: :has_model_ssim,
            resource_type: :resource_type_tesim,
            year_of_publication: :date_ssi,
            author: :creator_tesim,
            publisher: :publisher_tesim,
            title: :title_tesim
          }
        end

        attr_accessor :attribute_names_to_solr_names

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
