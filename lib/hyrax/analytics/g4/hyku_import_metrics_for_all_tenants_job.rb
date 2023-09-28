# frozen_string_literal: true

module Hyrax
  module Analytics
    module G4
      ##
      # Responsible for spinning off one job per tenant to fetch it's analytics.
      class HykuImportMetricsForAllTenantsJob < ::ApplicationJob
        non_tenant_job

        ##
        # @!group Class Attributes
        #
        # @!attribute import_metrics_class_name
        #
        #   @return [String] the name of the class that is responsible for performing the job.
        #           That class should conform to the ActiveJob interface and it's perform method
        #           takes two position parameters: host_name and property_id
        class_attribute :import_metrics_class_name, default: "G4::ImportMetricsJob"
        # @!endgroup Class Attributes
        ##

        def perform
          job_class = import_metrics_class_name.constantize
          Account.all.each do |account|
            account.switch! do
              job_class.perform(account.cname, account.google_analytics_property_number)
            end
          end
        end

        after_perform { |_job| reenqueue }

        # After we're done performing the job enqueue a job for tomorrow night
        def reenqueue
          self.class.set(wait_until: Date.tomorrow.midnight).perform_later
        end
      end
    end
  end
end
