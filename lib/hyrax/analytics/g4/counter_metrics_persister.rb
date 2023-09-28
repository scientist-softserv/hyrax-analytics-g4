# frozen_string_literal: true

module Hyrax
  module Analytics
    module G4
      ##
      # The {.call} method is responsible for persisting the accumulated metrics for a work into a
      # metrics database.
      #
      # @see .call
      module CounterMetricsPersister
        ##
        # Responsible for persisting the given work_metrics_set.
        #
        # @param work_metrics_set [G4::Accumulator::WorkMetricsSet]
        def self.call(work_metrics_set:)
          work_metrics_set.records.each do |attributes|
            __persist!(attributes: attributes)
          end
        end

        module ClassMethods
          module Hyrax
            def __persist!(attributes:)
              keys = attributes.slice(:work_id, :date)
              record = ::Hyrax::CounterMetric.find_by(**keys) || ::Hyrax::CounterMetric.new(**keys)

              record.update(attributes.except(:work_id, :date))
            end
          end

          module Test
            # rubocop:disable Rails/Output
            def __persist!(attributes:)
              puts attributes
            end
            # rubocop:enable Rails/Output
          end
        end
      end
      if defined?(Hyrax::Engine)
        CounterMetricsPersister.extend(CounterMetricsPersister::ClassMethods::Hyrax)
      else
        CounterMetricsPersister.extend(CounterMetricsPersister::ClassMethods::Test)
      end
    end
  end
end
