module Hyrax
  module Analytics
    module G4
      ##
      # The Accumulator is responsible for taking a row and filing it away in the correct location
      # (via the {#add} method).  We're also concerned with the given row having an ID that may or
      # may not be for a Work or FileSet; hence using the {G4.row_coercer}.
      class Accumulator
        ##
        # @param importer [CounterMetricImporter]
        def initialize(importer:)
          @set = {}
          @importer = importer
          @work_metadata_map = {}
        end
        attr_reader :importer

        ##
        # @param row [G4::RemoteDailyReport::Row]
        def add(row)
          # Given that we're working with are working with files sets and works, we want to have the
          # associated **work** metadata.
          work_metadata = @work_metadata_map.fetch(row.id) { WorkMetadata.fetch(row.id) }
          @work_metadata_map[row.id] = work_metadata unless @work_metadata_map.key?(row.id)

          return unless work_metadata

          if @set.key?(work_metadata.work_id)
            @set[work_metadata.work_id].add(row)
          else
            @set[work_metadata.work_id] = Accumulator::WorkMetricsSet.new(work_metadata: work_metadata, row: row, importer: importer)
          end
        end

        include Enumerable
        ##
        # @yieldparam work_id [String]
        # @yieldparam work_metrics_set [Accumulator::WorkMetricsSet]
        def each
          @set.each do |work_id, work_metrics_set|
            yield(work_id, work_metrics_set)
          end
        end

        class WorkMetricsSet
          ##
          # @param work_metadata [G4::WorkMetadata]
          # @param row [G4::RemoteDailyReport::Row, Object<#id, #date, #event_count>]
          # @param importer [CounterMetricImporter] necessary because the events that count as
          #        requests or investigations are known at the importer level.
          def initialize(work_metadata:, row:, importer:)
            @importer = importer
            @work_metadata = work_metadata
            @rows = {}
            add(row)
          end

          attr_reader :importer, :work_metadata

          def add(row)
            @rows[row.date] ||= []
            @rows[row.date] << row
          end

          def records
            @rows.map do |date, rows|
              work_metadata.to_h.merge(
                date: date,
                total_item_investigations: total_item_investigations(rows),
                total_item_requests: total_item_requests(rows)
              )
            end
          end

          private

          def total_item_investigations(rows)
            rows.sum { |row| investigation?(row) ? row.event_count.to_i : 0 }
          end

          def total_item_requests(rows)
            rows.sum { |row| request?(row) ? row.event_count.to_i : 0 }
          end

          def request?(row)
            importer.event_names_for_requests.include?(row.event_name)
          end

          def investigation?(row)
            importer.event_names_for_investigations.include?(row.event_name)
          end
        end
      end
    end
  end
end
