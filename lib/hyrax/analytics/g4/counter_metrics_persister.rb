module Hyrax
  module Analytics
    module G4
      module CounterMetricsPersister
        ##
        # Responsible to persisting the given works.
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
              record = Hyrax::CounterMetric.find_by(**keys) || Hyrax::CounterMetri.new(**keys)
              record.update(attributes.except(:work_id, :date))
            end
          end
          module Test
            def __persist!(attributes:)
              puts attributes
            end
          end
        end
        if defined?(Rails)
          CounterMetricsPersister.extend(ClassMethods::Hyrax)
        else
          CounterMetricsPersister.extend(ClassMethods::Test)
        end
      end
    end
  end
end
