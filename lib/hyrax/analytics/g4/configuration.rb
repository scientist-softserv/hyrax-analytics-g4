module Hyrax
  module Analytics
    module G4
      class Configuration
        def initialize
          # We're going to parrot the row back with the coercer.
          @row_coercer = -> (row) { row }
        end

        ##
        # @!attribute [rw] row_coercer
        #   @return [#call] a function that takes a positional paramter; likely a
        #           {Hyrax::Analytics::G4::RemoteDailyReport::Row}.
        attr_accessor :row_coercer
      end
    end
  end
end
