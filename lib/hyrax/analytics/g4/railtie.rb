# frozen_string_literal: true

module Hyrax
  module Analytics
    module G4
      class Railtie < Rails::Railtie
        config.to_prepare do
          if defined?(Hyku)
            ::Account.setting :google_analytics_property_number, type: 'integer'
            ::Account.validates :google_analytics_property_number, format: { with: %r{\d+} }, allow_blank: true
          end
        end
      end
    end
  end
end
