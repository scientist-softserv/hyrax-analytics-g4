# frozen_string_literal: true

module Hyrax
  module Analytics
    module G4
      ##
      # @note we do not automatically enqueue this job, because the host_name and property would
      #       continue to propogate.  In the case of this running within Hyku, the
      #       {G4::HykuImportMetricsForAllTenantsJob} handles the auto-reenquing; in
      #       part because it can requiry the host_name and property information.
      class ImportMetricsJob < ::Hyrax::ApplicationJob
        ##
        # @!group Class Attributes
        #
        # @!attribute [rw] importer_class_name
        #
        #   @return [String] the name of the class that has a call method with two named
        #           parameters: :host_name and :property.
        class_attribute :importer_class_name, default: 'G4::CounterMetricImporter'
        # @!endgroup Class Attributes
        ##

        ##
        # @param host_name [String] the host name of the analytics we're
        # to query; in the case of Hyku, this an account's :cname
        # (e.g. "dev.commons-archive.org").
        #
        # @param property [String] the google analytics property identifier (not what we see in
        #        the UI for javascript) nor what's visible in the credentials; but instead the ID
        #        when visiting the UI.
        def perform(host_name, property)
          importer_class_name.constantize.call(host_name: host_name, property: property)
        end
      end
    end
  end
end
