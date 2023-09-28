# frozen_string_literal: true

module Hyrax
  module Analytics
    module G4
      ##
      # Responsible for negotiating the configuration of a Hyrax application's utilization of the
      # {Hyrax::Analytics::G4} gem.
      class Configuration
        def initialize
          @google_analytics_page_limit = 25_000
          @limit_to_this_many_days = 3
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

        ##
        # The number of records to fetch per request to Google Analytics API.
        #
        # @return [Integer]
        attr_reader :google_analytics_page_limit
        def google_analytics_page_limit=(value)
          @google_analytics_page_limit = Integer(value)
        end

        ##
        # When we are writing to {Hyrax::CounterMetric}, we want to have a narrow window of time
        # for which we are retrieving data; the idea being that we've already done stuff in the
        # past.
        attr_reader :limit_to_this_many_days
        def limit_to_this_many_days=(value)
          @limit_to_this_many_days = Integer(value)
        end

        attr_reader :attribute_names_to_solr_names

        ##
        # @param attr_name [#to_sym] the named attribute on {G4::WorkMetadata}
        # @param solr_key [#to_sym] the named attribute for the the SolrDocument.
        #
        # @raise [G4::Error] when the given :attr_name is not one of {G4::WorkMetadata}'s
        #        attributes.
        def register_attribute_map_to_solr_key(attr_name, solr_key:)
          attr_name = attr_name.to_sym
          solr_key = solr_key.to_sym
          valid_props = WorkMetadata.instance_methods(false).select { |method| !method.end_with?("=") }
          raise G4::Error, "Expected given attr_name of #{attr_name} to be one of the following: #{valid_props.join(', ')}" unless valid_props.include?(attr_name)

          @attribute_names_to_solr_names[attr_name] = solr_key
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
