# frozen_string_literal: true

module Hyrax
  module Analytics
    module G4
      ##
      # This is the class responsible for:
      #
      # - grabbing the analytics data (via {G4::RemoteDailyReport})
      # - collating the analytics with the works (via {G4::Accumulator})
      # - persisting the collated information (via {G4::CounterMetricsPersister})
      #
      # The above is codified in the {#call} method.
      class CounterMetricImporter
        ##
        # This convenience method forward delegates to the {#initialize} then {#call}
        def self.call(**kwargs)
          new(**kwargs).call
        end

        ##
        # @!group Class Attributes
        #
        # @!attribute event_names_for_investigations
        #   @return [Array<String>]
        #
        #   Yes there are duplications; this is because in some cases when I got to the work I see
        #   the Image Viewer and that counts as requesting it as well as investigating it.
        #
        #   @note these are defined in Hyrax
        #   @see .event_names_for_requests
        class_attribute :event_names_for_investigations, default: ["work-view"]

        # @!attribute event_names_for_investigations
        #   @return [Array<String>]
        #
        #   @note these are defined in Hyrax
        #   @see .event_names_for_investigations
        class_attribute :event_names_for_requests, default: ["work-view",
                                                             "file-set-download",
                                                             "work-in-collection-download",
                                                             "file-set-in-work-download",
                                                             "file-set-in-collection-download"]
        # @!endgroup Class Attributes
        ##

        def initialize(host_name:, property:, credentials:, **options)
          @host_name = host_name
          @credentials = credentials
          @start_date = options.fetch(:start_date) { G4.limit_to_this_many_days.days.ago.to_date }
          @end_date = options.fetch(:end_date) { 1.day.ago.to_date }
          @property = property
        end
        attr_reader :host_name, :credentials, :end_date, :property, :start_date

        ##
        # When querying Google, we want to pass along the event_names we want to filter for.  This
        # is that list.
        #
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
