# frozen_string_literal: true

module Hyrax
  module Analytics
    module G4
      ##
      # A data structure representing the work specific metadata we persist in the
      # {Hyrax::CounterMetrics}.
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
          def fetch(id)
            raise NotImplementedError, "#{self}.#{__method__}"
          end
        end

        module Test
          def fetch(id)
            new(
              author: Faker::Name.name,
              publisher: Faker::Company.name,
              resource_type: "Article",
              title: Faker::Book.title,
              work_id: id,
              worktype: "GenericWork",
              year_of_publication: 1950 + rand(74),
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
