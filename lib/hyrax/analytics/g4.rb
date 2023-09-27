# frozen_string_literal: true

require_relative "g4/version"
require "google/analytics/data/v1beta"
require 'active_support/all'
require 'faker'

module Hyrax
  module Analytics
    module G4
      class Error < StandardError; end

      autoload :Accumulator, "hyrax/analytics/g4/accumulator"
      autoload :CounterMetricImporter, "hyrax/analytics/g4/counter_metric_importer"
      autoload :CounterMetricsPersister, "hyrax/analytics/g4/counter_metrics_persister"
      autoload :RemoteDailyReport, "hyrax/analytics/g4/remote_daily_report"
      autoload :WorkMetadata, "hyrax/analytics/g4/work_metadata"

      ##
      # @yieldparam config [Configuration]
      #
      # @example
      #   Hyrax::Analytics::G4.config do |config|
      #     config.register_coercer(key: :author) do |value|
      #       Sushi::AuthorCoercion.serialize(value)
      #     end
      #   end
      def self.config
          @config ||= Configuration.new
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
        coercer = config.coercer_for(key)
        coercer.call(value)
      end
    end
  end
end

# Provided as a convenience method for typing and testing.
Report = Hyrax::Analytics::G4::CounterMetricImporter
