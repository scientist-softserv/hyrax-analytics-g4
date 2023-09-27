module Hyrax
  module Analytics
    module G4
      class Configuration
        def initialize
          # We're going to parrot the row back with the coercer.
          @work_metadata_fetcher = -> (id) do
            WorkMetadata.new(

            )
          end
        end

        ##
        # @!attribute [rw] work_metadata_fetcher
        #   @return [#call] a function that takes an :id as a positional parameter and returns
        #                   a metadata for the given :id.
        attr_accessor :work_metadata_fetcher
      end
    end
  end
end
