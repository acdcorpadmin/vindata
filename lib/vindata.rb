# External gems
require 'rest_client' if defined?(RestClient)

# Internal files
require 'vindata/configuration'
require 'vindata/services'

module VinData
  def self.details_by_vin vin
    service = Services.get config[:service]
    service.details_by_vin vin
  end

  def self.get_acv data
    service = Services.get config[:service]
    service.get_acv data
  end
end
