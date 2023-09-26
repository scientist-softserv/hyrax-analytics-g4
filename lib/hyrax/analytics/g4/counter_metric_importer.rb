module Hyrax
  module Analytics
    module G4
      class Accumulator
        def initialize(importer:)
          @set = {}
          @importer = importer
        end
        attr_reader :importer

        def add(row)
          if @set.key?(row.id)
            @set[row.id].add(row)
          else
            @set[row.id] = RowAccumulator.new(row: row, importer: importer)
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
      end

      class RowAccumulator
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

      ##
      #
      class CounterMetricImporter
        ##
        # @note the default value is a holding value while I iterate.
        def self.call(cname: "dev.commons-archive.org", property: "395286330", **kwargs)
          new(cname: cname, property: property, **kwargs).call
        end

        # Yes there are duplications; this is because in some cases when I got to the work I see the
        # Image Viewer and that counts as requesting it as well as investigating it.
        class_attribute :event_names_for_investigations, default: ["work-view"]
        class_attribute :event_names_for_requests, default:  ["work-view",
                                                              "file-set-download",
                                                              "work-in-collection-download",
                                                              "file-set-in-work-download",
                                                              "file-set-in-collection-download"]

        def initialize(cname:, property:, start_date: 8.days.ago.to_date, end_date: 1.days.ago.to_date)
          @cname = cname
          @start_date = start_date
          @end_date = end_date
          @property = property
        end
        attr_reader :start_date, :end_date, :cname, :property
        alias host_name cname

        def event_names
          (event_names_for_investigations + event_names_for_investigations).uniq
        end

        def call
          accumulator = Accumulator.new(importer: self)

          RemoteDailyReport.call(importer: self) { |row| accumulator.add(row) }

          accumulator
        end
      end
    end
  end
end
