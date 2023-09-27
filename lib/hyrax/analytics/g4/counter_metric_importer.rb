# frozen_string_literal: true

module Hyrax
  module Analytics
    module G4
      class CounterMetricImporter
        ##
        # @note the default value is a holding value while I iterate.
        def self.call(**kwargs)
          new(**kwargs).call
        end

        # Yes there are duplications; this is because in some cases when I got to the work I see the
        # Image Viewer and that counts as requesting it as well as investigating it.
        class_attribute :event_names_for_investigations, default: ["work-view"]
        class_attribute :event_names_for_requests, default: ["work-view",
                                                             "file-set-download",
                                                             "work-in-collection-download",
                                                             "file-set-in-work-download",
                                                             "file-set-in-collection-download"]

        def initialize(cname:, property:, credentials:, **options)
          @cname = cname
          @credentials = credentials
          @start_date = options.fetch(:start_date) { G4.limit_to_this_many_days.days.ago.to_date }
          @end_date = options.fetch(:end_date) { 1.day.ago.to_date }
          @property = property
        end
        attr_reader :cname, :credentials, :end_date, :property, :start_date
        alias host_name cname

        ##
        # @return [Array<String>]
        def event_names
          (event_names_for_investigations + event_names_for_investigations).uniq
        end

        def call
          accumulator = Accumulator.new(importer: self)

          # The daily report does not guarantee that we'll get back data in a well ordered manner
          # (e.g. by id then date); as such we need to accumulate this information.
          RemoteDailyReport.call(importer: self) { |row| accumulator.add(row) }

          accumulator.each do |_, work_metrics_set|
            CounterMetricsPersister.call(work_metrics_set: work_metrics_set)
          end

          accumulator.count
        end
      end
    end
  end
end
