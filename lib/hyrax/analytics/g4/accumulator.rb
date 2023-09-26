module Hyrax
  module Analytics
    module G4
      class Accumulator
        def initialize(importer:)
          @set = {}
          @importer = importer
          @row_coercer = G4.row_coercer
        end
        attr_reader :importer, :row_coercer

        def add(row)
          row = row_coercer.call(row)
          if @set.key?(row.id)
            @set[row.id].add(row)
          else
            @set[row.id] = Accumulator::Row.new(row: row, importer: importer)
          end
        end

        include Enumerable
        def each
          @set.each do |key, accumulator|
            yield(key, accumulator)
          end
        end

        def as_json
          @set.map do |key, value|
            { key => value.metrics }
          end
        end

        class Row
          ##
          # @param row [G4::Row, Object<#id, #date, #event_count>]
          # @param importer [CounterMetricImporter] necessary because the events that count as
          #        requests or investigations are known at the importer level.
          def initialize(row:, importer:)
            @id = row.id
            @importer = importer
            @rows = {}
            add(row)
          end

          attr_reader :id, :importer

          def add(row)
            @rows[row.date] ||= []
            @rows[row.date] << row
          end

          def metrics
            @rows.map do |date, rows|
              {
                date: date,
                total_item_investigations: total_item_investigations(rows),
                total_item_requests: total_item_requests(rows)
              }
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
