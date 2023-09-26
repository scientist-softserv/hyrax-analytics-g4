# frozen_string_literal: true

require_relative "g4/version"
require "google/analytics/data/v1beta"

module Hyrax
  module Analytics
    module G4
      class Error < StandardError; end

      INVESTIGATIONS_EVENT_NAME = ["work-view"]
      REQUESTS_EVENT_NAME = ["file-set-download",
                             "work-in-collection-download",
                             "file-set-in-work-download",
                             "file-set-in-collection-download"]

      ##
      # Creating a Struct so we can see what the data is instead of relying on the positional nature
      # of the returned results.
      Result = Struct.new(:date, :event_name, :page_location, :host_name, :event_count, keyword_init: true) do
        def id
          page_location.split('/').last
        end

        def request?
          G4::REQUESTS_EVENT_NAME.include?(event_name)
        end

        def investigation?
          G4::INVESTIGATIONS_EVENT_NAME.include?(event_name)
        end
      end

      ##
      # @param property [String] this is identifier of the property as indicated in the UI.  It is
      #        not the analytics code (e.g. "G-RANDOM123") in the UI nor is it found in the values
      #        of the analytics credentials JSON with keys of: "type", "project_id",
      #        "private_key_id", "private_key", "client_email", "client_id", "auth_uri",
      #        "token_uri", "auth_provider_x509_cert_url", "client_x509_cert_url",
      #        "universe_domain").
      #
      # @param host_name [String] the host name (e.g. "sub.domain.com") there is likely a relation
      #        between the host_name and the property; but for now I'm keeping these separate.  We
      #        provide the host_name because the Hyrax's counter metrics table is partitioned on a
      #        per tenant basis.
      #
      # @param start_date [Date, #iso8601]
      # @param end_date [Date, #iso8601]
      # @param limit [Integer]
      # @param offset [Integer]
      #
      # @return [Array<G4::Result>] sorted by {G4::Result#id}
      def self.call(property: "395286330", host_name: "dev.commons-archive.org", start_date: Date.new(2023,8,1), end_date: Date.new(2023,9,24), limit: 25_000, offset: 0)
        client = ::Google::Analytics::Data::V1beta::AnalyticsData::Client.new
        returning_value = []

        loop do
          # For details on the schema: https://developers.google.com/analytics/devguides/reporting/data/v1/api-schema
          # For examples in the wild: https://github.com/JasonBarnabe/greasyfork/blob/master/lib/google_analytics.rb
          request = ::Google::Analytics::Data::V1beta::RunReportRequest.new(
            property: "properties/#{property}",
            date_ranges: [{ start_date: start_date.iso8601, end_date: end_date.iso8601 }],
            # NOTE: The order of dimensions and metrics matter; because the return results will be rows
            dimensions: [{ name: 'date' }, { name: 'eventName' }, { name: 'pagePath' }, { name: 'hostName' }],
            metrics: [{ name: 'eventCount' }],
            ##
            # See https://developers.google.com/analytics/devguides/reporting/data/v1/advanced#weekly_cohorts_and_using_cohorts_with_other_api_features
            # See https://developers.google.com/analytics/devguides/reporting/data/v1/rest/v1alpha/FilterExpression
            dimension_filter: {
              and_group: {
                expressions: [
                  {
                    filter: {
                      field_name: 'hostName',
                      string_filter: { match_type: "EXACT", value: host_name, case_sensitive: false } }
                  }, {
                    filter: {
                      field_name: 'eventName',
                      in_list_filter: { values: G4::INVESTIGATIONS_EVENT_NAME + G4::REQUESTS_EVENT_NAME } } }] } },
            limit: limit,
            offset: offset
          )
          results = client.run_report(request)

          this_results = results.rows.map do |result|
            # The position of the dimension values is based on the order in which they are specified
            # above.
            Result.new(
              date: Date.parse(result.dimension_values[0].value),
              event_name: result.dimension_values[1].value,
              page_location: result.dimension_values[2].value,
              host_name: result.dimension_values[3].value,
              event_count: result.metric_values[0].value.to_i
            )
          end

          returning_value += this_results
          # No sense making another request if got less than the limit.
          break if this_results.size < limit
          offset += limit
        end

        ##
        # For later processing we'll be looping through in order.
        returning_value.sort_by(&:id)
      end
    end
  end
end

# Provided as a helper for testing in bin/console; remove this eventually.
::G4 = Hyrax::Analytics::G4
