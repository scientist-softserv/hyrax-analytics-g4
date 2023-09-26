module Hyrax
  module Analytics
    module G4
      class RowAggregate
        ##
        # @param row [G4::Row, Object<#id, #date, #event_count>]
        # @param importer [CounterMetricImporter] necessary because the events that count as
        #        requests or investigations are known at the importer level.
        def initialize(row:, importer:)
          @id = row.id
          @date = row.date
          @importer = importer
          @rows = [row]
        end

        def sort_order
          [id, date]
        end

        attr_reader :id, :importer, :date

        def add(row)
          @rows << row
        end

        def total_item_investigations
          @rows.sum { |row| investigation?(row) ? row.event_count.to_i : 0 }
        end

        def total_item_requests
          @rows.sum { |row| request?(row) ? row.event_count.to_i : 0 }
        end

        ##
        # I need to coerce the id into a work_id based on the type of object.  I'm also envisioning
        # an external process that will get the other attributes necessary for a
        # {Hyrax::CounterMetric} record.
        def as_json
          {
            id: id,
            date: date,
            total_item_investigations: total_item_investigations,
            total_item_requests: total_item_requests
          }
        end

        private

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
        def self.call(cname: "dev.commons-archive.org", **kwargs)
          new(cname: cname, **kwargs).call
        end

        # Yes there are duplications; this is because in some cases when I got to the work I see the
        # Image Viewer and that counts as requesting it as well as investigating it.
        class_attribute :event_names_for_investigations, default: ["work-view"]
        class_attribute :event_names_for_requests, default:  ["work-view",
                                                              "file-set-download",
                                                              "work-in-collection-download",
                                                              "file-set-in-work-download",
                                                              "file-set-in-collection-download"]

        def initialize(cname:, start_date: 3.days.ago.to_date, end_date: 1.days.ago.to_date)
          @cname = cname
          @start_date = start_date
          @end_date = end_date
        end
        attr_reader :start_date, :end_date, :cname
        alias host_name cname

        def call
          rows = RemoteDailyReport.call(
            start_date: start_date,
            end_date: end_date,
            host_name: host_name,
            event_names: event_names_for_investigations + event_names_for_investigations
          )
          aggregates = []
          aggregate = nil

          rows.each do |row|
            if aggregate.blank? || aggregate.sort_order != row.sort_order
              aggregate = RowAggregate.new(importer: self, row: row)
              aggregates << aggregate
            else
              aggregate.add(row)
            end
          end

          aggregates
        end
      end
    end
  end
end
