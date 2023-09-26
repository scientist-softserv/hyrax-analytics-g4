module Hyrax
  module Analytics
    module G4
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

        ##
        # @return [G4::Accumulator]
        def call
          accumulator = Accumulator.new(importer: self)

          RemoteDailyReport.call(importer: self) { |row| accumulator.add(row) }

          accumulator
        end
      end
    end
  end
end
