# frozen_string_literal: true

require_relative "g4/version"
require "google/analytics/data/v1beta"

module Hyrax
  module Analytics
    module G4
      class Error < StandardError; end

      ##
      # Creating a Struct so we can see what the data is instead of relying on the positional nature
      # of the returned results.
      Result = Struct.new(:date, :event_name, :page_location, :host_name, :event_count, keyword_init: true) do
        def id
          page_location.split('/').last
        end
      end

      def self.call
        client = ::Google::Analytics::Data::V1beta::AnalyticsData::Client.new
        # For details on the schema: https://developers.google.com/analytics/devguides/reporting/data/v1/api-schema
        # For examples in the wild: https://github.com/JasonBarnabe/greasyfork/blob/master/lib/google_analytics.rb
        request = ::Google::Analytics::Data::V1beta::RunReportRequest.new(
          # This is the roll-up identifier as indicated in the UI.  You need to prefix this, I think,
          # with the "properties/" string.
          property: "properties/395286330",
          date_ranges: [{ start_date: "2023-09-22", end_date: "2023-09-24" }],
          # Note: The order of dimensions and metrics matter
          dimensions: [{ name: 'date' }, { name: 'eventName' }, { name: 'pagePath' }, { name: 'hostName' }],
          metrics: [{ name: 'eventCount' }],
          ##
          # See https://developers.google.com/analytics/devguides/reporting/data/v1/advanced#weekly_cohorts_and_using_cohorts_with_other_api_features
          dimension_filter: { filter: { field_name: 'eventName', in_list_filter: { values: ["work-view", "file-set-download"] } } },
          limit: 25_000,
          offset: 0
        )

        results = client.run_report request

        results.rows.map do |result|
          Result.new(
            date: Date.parse(result.dimension_values[0].value),
            event_name: result.dimension_values[1].value,
            page_location: result.dimension_values[2].value,
            host_name: result.dimension_values[3].value,
            event_count: result.metric_values[0].value.to_i
          )
        end
      end
    end
  end
end

::G4 = Hyrax::Analytics::G4
