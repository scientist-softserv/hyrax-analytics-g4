# frozen_string_literal: true

require_relative "g4/version"
require "google/analytics/data/v1beta"
require 'active_support'

module Hyrax
  module Analytics
    module G4
      class Error < StandardError; end

      autoload :CounterMetricsReport, "hyrax/analytics/g4/counter_metrics_report"
    end
  end
end

# Provided as a convenience method for typing and testing.
Report = Hyrax::Analytics::G4::CounterMetricsReport
