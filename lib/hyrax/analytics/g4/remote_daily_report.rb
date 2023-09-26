# frozen_string_literal: true

module Hyrax
  module Analytics
    module G4
      ##
      # The purpose of this class is to query Google Analytics and return a {Row} that can be used
      # to help write a record to {Hyrax::CounterMetric}.
      #
      # To populate the counter metric we need the following dimensions:
      #
      # - date :: the date that the event occurred
      # - eventName :: the name of the event we're interested in (see {EVENT_NAME_INVESTIGATIONS}
      #                and {EVENT_NAME_REQUESTS}).
      # - pagePath :: path on the host name, without query parameters
      #               (e.g. /concerns/generic_work/1234-abcd)
      # - hostName :: technically not needed but useful in debugging the results.  (see {#host_name})
      #
      # We need the following metric:
      #
      # - eventCount :: the number of times in the given :date the given :eventName occurred for the
      #                 given :pagePath and :hostName.
      #
      # @see #call
      # @see https://developers.google.com/analytics/devguides/reporting/data/v1/api-schema# For details on the dimensions and metrics schema
      class RemoteDailyReport
        ##
        # A convenience method for querying Google Analytics.
        #
        # @see #initialize
        # @see #call
        # @return [Array<Row>]
        def self.call(**kwargs)
          new(**kwargs).call
        end

        ##
        # @param credentials [String, Hash] the credentials necessary for authenticating to the
        #        Google Analytics API.
        #
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
        # @param event_names [Array<String>]
        def initialize(event_names:,
                       start_date:,
                       host_name:,
                       end_date:,
                       credentials: "./config/analytics.json",
                       property: "395286330",
                       limit: 25_000,
                       offset: 0)
          @client = ::Google::Analytics::Data::V1beta::AnalyticsData::Client.new do |config|
            config.credentials = case credentials
                                 when String
                                   if File.exist?(credentials)
                                     JSON.parse(File.read(credentials))
                                   else
                                     JSON.parse(credentials)
                                   end
                                 when Hash
                                   credentials
                                 end
          end
          @end_date = end_date
          @event_names = event_names
          @host_name = host_name
          @limit = limit
          @offset = offset
          @property = property
          @start_date = start_date
        end
        attr_reader :client, :end_date, :event_names, :host_name, :limit, :offset, :property, :start_date

        ##
        # Creating a Struct so we can see what the data is instead of relying on the positional nature
        # of the returned results.
        Row = Struct.new(:date, :event_name, :page_path, :host_name, :event_count, keyword_init: true) do
          ##
          # By convention the last element of the path is the identifier of the Work and/or FileSet
          def id
            page_path.split('/').last
          end

          ##
          # Later in processing, we're going to want to lookup the work/fileSet by ID and we'll want
          # to aggregate the events that are part of {EVENT_NAME_REQUESTS} and
          # {EVENT_NAME_INVESTIGATIONS} to create a single record in {Hyrax::Counter}.
          def sort_order
            [id, date]
          end
        end

        ##
        # @return [Array<CounterMetricsReport::Row>] sorted by {CounterMetricsReport::Row#sort_order}
        def call
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
                        in_list_filter: { values: event_names.uniq } } }] } },
              limit: limit,
              offset: offset
            )
            results = client.run_report(request)

            this_results = results.rows.map do |result|
              # The position of the dimension values is based on the order in which they are specified
              # above.
              Row.new(
                date: Date.parse(result.dimension_values[0].value),
                event_name: result.dimension_values[1].value,
                page_path: result.dimension_values[2].value,
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
          returning_value.sort_by(&:sort_order)
        end
      end
    end
  end
end
