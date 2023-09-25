# frozen_string_literal: true

require_relative "g4/version"

module Hyrax
  module Analytics
    module G4
      class Error < StandardError; end
      # Your code goes here...

      require "google/analytics/data/v1beta"

      def self.call
        client = ::Google::Analytics::Data::V1beta::AnalyticsData::Client.new
        # For details on the schema: https://developers.google.com/analytics/devguides/reporting/data/v1/api-schema
        # For examples in the wild: https://github.com/JasonBarnabe/greasyfork/blob/master/lib/google_analytics.rb
        request = ::Google::Analytics::Data::V1beta::RunReportRequest.new(
          # This is the roll-up identifier as indicated in the UI.  You need to prefix this, I think,
          # with the "properties/" string.
          property: "properties/395286330",
          date_ranges: [{ start_date: "2023-08-01", end_date: "2023-09-24" }],
          dimensions: [{ name: 'date' }, { name: 'pagePath' }],
          metrics: [{ name: 'screenPageViews' }]
        )

        response = client.run_report request
      end
    end
  end
end

::G4 = Hyrax::Analytics::G4
