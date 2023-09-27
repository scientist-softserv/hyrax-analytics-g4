# frozen_string_literal: true

module Hyrax
  module Analytics
    module G4
      ##
      # A data structure representing the work specific metadata we persist in the
      # {Hyrax::CounterMetrics}.
      #
      # @see {G4::Configuration.attribute_names_to_solr_names}
      WorkMetadata = Struct.new(
        :author,
        :publisher,
        :resource_type,
        :title,
        :work_id,
        :worktype,
        :year_of_publication,
        keyword_init: true
      )

      module WorkMetadata::ClassMethods
        module Hyrax
          ##
          # Fetch the work associated with the given :id and then cast that work's metadata
          # attributes to the correct format.  We use the {G4.coerce_solr_document} to map the
          # attributes we retrieved because there may be additional considerations on how we convert
          # that information.
          #
          # @param id [String]
          # @return [G4::WorkMetadata] when we find a match
          # @return [NilClass] when we don't find a match in SOLR
          def fetch(id)
            solr_keys = G4.attribute_names_to_solr_names.values.map(&:to_s)
            document = ActiveFedora::SolrService.query("id:#{id}", { rows: 1, fl: solr_keys.join(", "), method: :post }).first
            return if doc.blank?

            attributes = G4.attribute_names_to_solr_names.each_with_object({}) do |(attribute_name, solr_field), hash|
              hash[attribute_name] = G4.coerce_metadata(key: attribute_name, value: document[solr_field.to_s])
            end

            # TODO: Inspect if we have a FileSet; if we don't we'll need to again query based on the object's parent id
            new(**attributes)
          end
        end

        module Test
          ##
          # A mechanism for providing semi-random metadata.
          #
          # @param id [String]
          # @return [G4::WorkMetadata]
          def fetch(id)
            new(
              author: ["Dyan Schneider",
                       "Rev. Jeromy Towne",
                       "The Hon. Lacie Cummerata",
                       "Lizzette Jacobs LLD",
                       "Willian Wehner",
                       "Hwa Champlin",
                       "Dr. Kai Collins",
                       "Sunny Mueller",
                       "Kala Huel DC",
                       "Kristina Klein"].sample,
              publisher: ["Nienow Group",
                          "Dietrich, Macejkovic and Bergstrom",
                          "Wolf Inc",
                          "Dickens Group",
                          "Hodkiewicz LLC",
                          "Bahringer, Hartmann and Pagac",
                          "Windler, Spencer and Huel",
                          "Schowalter-Dicki",
                          "Miller-Hessel",
                          "Langosh LLC"].sample,
              resource_type: "Article",
              title: ["Surprised by Joy",
                      "Mother Night",
                      "A Farewell to Arms",
                      "Stranger in a Strange Land",
                      "Quo Vadis",
                      "Frequent Hearses",
                      "In Death Ground",
                      "The Stars' Tennis Balls",
                      "Let Us Now Praise Famous Men",
                      "The Daffodil Sky"].sample,
              work_id: id,
              worktype: "GenericWork",
              year_of_publication: 1950 + rand(74)
            )
          end
        end
      end

      if defined?(Rails)
        WorkMetadata.extend(WorkMetadata::ClassMethods::Hyrax)
      else
        WorkMetadata.extend(WorkMetadata::ClassMethods::Test)
      end
    end
  end
end
