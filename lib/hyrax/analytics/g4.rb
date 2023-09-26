# frozen_string_literal: true

require_relative "g4/version"
require "google/analytics/data/v1beta"
require 'active_support/all'

module Hyrax
  module Analytics
    module G4
      class Error < StandardError; end

      autoload :Accumulator, "hyrax/analytics/g4/accumulator"
      autoload :Configuration, "hyrax/analytics/g4/configuration"
      autoload :CounterMetricImporter, "hyrax/analytics/g4/counter_metric_importer"
      autoload :RemoteDailyReport, "hyrax/analytics/g4/remote_daily_report"

      ##
      # @return [Configuration]
      # @yieldparam config [Configuration]
      def self.config
        @config ||= Configuration.new
        yield(@config) if block_given?
        @config
      end

      class << self
        delegate :row_coercer, to: :config
      end
    end
  end
end

# Provided as a convenience method for typing and testing.
Report = Hyrax::Analytics::G4::CounterMetricImporter
