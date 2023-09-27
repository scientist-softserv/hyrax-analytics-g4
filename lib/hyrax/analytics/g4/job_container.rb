# frozen_string_literal: true

module Hyrax
  module Analytics
    module G4
      ##
      # The {JobContainer} is responsible for coordinating which jobs are defined based on the state
      # of the containing application.
      module JobContainer
        autoload :ImportMetricsJob, "hyrax/analytics/g4/job_container/import_metrics_job"
        autoload :HykuImportMetricsForAllTenantsJob, "hyrax/analytics/g4/job_container/hyku_import_metrics_for_all_tenants_job" if defined?(Hyku)
      end
    end
  end
end
