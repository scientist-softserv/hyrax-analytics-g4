# frozen_string_literal: true

require_relative "g4/version"
require 'active_support/all'

begin
  require "google/analytics/data/v1beta"
rescue LoadError
  $stderr.puts "Unable to load 'google/analytics/data/v1beta'; this is okay unless you're trying to query live data."
end

require_relative 'g4/railtie' if defined?(Rails)

module Hyrax
  module Analytics
    module G4
      class Error < StandardError; end

      autoload :Accumulator, "hyrax/analytics/g4/accumulator"
      autoload :Configuration, "hyrax/analytics/g4/configuration"
      autoload :CounterMetricImporter, "hyrax/analytics/g4/counter_metric_importer"
      autoload :CounterMetricsPersister, "hyrax/analytics/g4/counter_metrics_persister"
      autoload :HykuImportMetricsForAllTenantsJob, "hyrax/analytics/g4/hyku_import_metrics_for_all_tenants_job" if defined?(Hyku)
      autoload :ImportMetricsJob, "hyrax/analytics/g4/import_metrics_job" if defined?(Hyrax::Engine)
      autoload :RemoteDailyReport, "hyrax/analytics/g4/remote_daily_report"
      autoload :WorkMetadata, "hyrax/analytics/g4/work_metadata"

      ##
      # @yieldparam config [Configuration]
      #
      # @example
      #   Hyrax::Analytics::G4.config do |config|
      #     # Registering a specific coercer for the given author.
      #     config.register_coercer(key: :author) do |value|
      #       Sushi::AuthorCoercion.serialize(value)
      #     end
      #
      #     # Specifying that we find the :title value in the SolrDocument's :title_ssi "slot"
      #     config.register_attribute_map_to_solr_key(:title, solr_key: :title_ssi)
      #
      #     # We'll fetch data that's this many days old or newer.  Probably a good idea to peek
      #     # back a 2 or 3 days as the data "settles" into consistency.
      #     config.limit_to_this_many_days = 2
      #
      #     # That's probably too big of a number; consider something smaller?
      #     config.google_analytics_page_limit = 1_000_000
      #   end
      def self.config
        @config ||= G4::Configuration.new
        yield(@config) if block_given?
        @config
      end

      ##
      # @param key [Symbol]
      # @param value [Object]
      #
      # @return [Object] the value coerced by the coercer registered for the given :key.
      #
      # @see G4::Configuration#coercer_for
      def self.coerce_metadata(key:, value:)
        coercer = config.metadata_coercer_for(key)
        coercer.call(value)
      end

      class << self
        delegate :attribute_names_to_solr_names, :google_analytics_page_limit, :limit_to_this_many_days, to: :config
      end
    end
  end
end
