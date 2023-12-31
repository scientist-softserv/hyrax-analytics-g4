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
      # - eventName :: the name of the event we're interested in (see
      #                {CounterMetricImporter#event_names}).
      #
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
        # Creating a Struct so we can see what the data is instead of relying on the positional nature
        # of the returned results.  This structure describes what other
        Row = Struct.new(:date, :event_name, :page_path, :host_name, :event_count, keyword_init: true) do
          ##
          # By convention the last element of the path is the identifier of the Work and/or FileSet
          def id
            page_path.split('/').last
          end
        end

        ##
        # @!group Class Attributes
        #
        # @!attribute report_builder_class
        #   Provided as a means of creating a fake set of metrics.
        #
        #   @example
        #     ##
        #     # To leverage the {RemoteDailyReport::Fake} implementation.
        #     Hyrax::Analytics::G4::RemoteDailyReport.report_builder_class = Hyrax::Analytics::G4::RemoteDailyReport::Fake
        #
        #   @return [#call]
        class_attribute :report_builder_class, default: self, instance_accessor: false
        # @!endgroup Class Attributes
        ##

        ##
        # A convenience method for querying Google Analytics.
        #
        # @see #initialize
        # @see #call
        # @return [Array<Row>]
        def self.call(**kwargs, &block)
          report_builder_class.new(**kwargs).call(&block)
        end

        ##
        # @param importer [G4::CounterMetricImporter] this contains lots of configuration logic.
        # @param limit [Integer]
        # @param offset [Integer]
        def initialize(importer:,
                       limit: G4.google_analytics_page_limit,
                       offset: 0,
                       **_kwargs)
          @importer = importer
          @limit = limit
          @offset = offset
          configure_client!(importer.credentials)
        end
        attr_reader :client, :limit, :offset, :importer
        delegate :end_date, :event_names, :host_name, :property, :start_date, to: :importer

        ##
        # @note This is a still uncertain way to do this.
        def configure_client!(credentials)
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
        end
        private :configure_client!

        ##
        # @return [Array<CounterMetricsReport::Row>] sorted by CounterMetricsReport::Row#id
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/BlockLength
        # rubocop:disable Metrics/MethodLength
        def call
          # Getting a local binding of the provided offset so we can increment that offset.
          offset = self.offset.dup
          loop do
            # For details on the schema: https://developers.google.com/analytics/devguides/reporting/data/v1/api-schema
            # For examples in the wild: https://github.com/JasonBarnabe/greasyfork/blob/master/lib/google_analytics.rb
            request = ::Google::Analytics::Data::V1beta::RunReportRequest.new(
              property: "properties/#{property}",
              date_ranges: [{ start_date: start_date.iso8601, end_date: end_date.iso8601 }],
              # NOTE: The order of dimensions and metrics matter; because the return results will be rows
              dimensions: [{ name: 'pagePath' }, { name: 'date' }, { name: 'eventName' }, { name: 'hostName' }],
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
                        string_filter: { match_type: "EXACT", value: host_name, case_sensitive: false }
                      }
                    }, {
                      filter: {
                        field_name: 'eventName',
                        in_list_filter: { values: event_names.uniq }
                      }
                    }
                  ]
                }
              },
              limit: limit,
              offset: offset
            )
            results = client.run_report(request)
            results.rows.each do |result|
              # The position of the dimension values is based on the order in which they are specified
              # above.
              row = Row.new(
                page_path: result.dimension_values[0].value,
                date: Date.parse(result.dimension_values[1].value),
                event_name: result.dimension_values[2].value,
                host_name: result.dimension_values[3].value,
                event_count: result.metric_values[0].value.to_i
              )
              yield(row)
            end

            break if results.rows.size < limit
            offset += limit
          end
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/BlockLength
        # rubocop:enable Metrics/MethodLength

        ##
        # A means of faking data from Google Analytics.  Trust me, coordinating wedding analytics
        # data to works in your local instance is challenging.  Why not just create some fake
        # analytics for testing?
        #
        # @see RemoteDailyReport.report_builder_class
        class Fake < RemoteDailyReport
          ##
          # Exposed as a means for you dear code spelunker to generate your own page paths.
          #
          # @example
          #   Hyrax::Analytics::G4::RemoteDailyReport::Fake.page_path_generator = -> do
          #     GenericWork.limit(10).each do |gw|
          #       "/concern/generic_work/#{gw.id}"
          #     end
          #   end
          class_attribute :page_path_generator, default: lambda {
            (1..20).map do |_i|
              "/concern/something/#{SecureRandom.base36(8)}"
            end
          }

          def configure_client!(*); end

          def page_paths
            @page_paths ||= page_path_generator.call
          end

          def call
            (start_date.to_date..end_date.to_date).each do |date|
              page_paths.each do |page_path|
                # Let's simulate the chance of not having entries for a work on a given date
                next if rand(4).zero?
                event_names.shuffle[0..rand(event_names.size)].each do |event_name|
                  yield Row.new(
                          page_path: page_path,
                          date: date,
                          event_name: event_name,
                          host_name: host_name,
                          event_count: 1 + rand(10)
                        )
                end
              end
            end
          end
        end
      end
    end
  end
end
