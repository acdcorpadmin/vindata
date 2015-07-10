# External gems
require 'rest_client' if defined?(RestClient)

# Internal files
require 'vindata/configuration'
require 'vindata/services'

module VinData
  def self.details_by_vin vin, service = config[:service]
    service = Services.get service
    service.details_by_vin vin
  end

  def self.get_acv data, service = config[:service]
    service = Services.get service
    service.get_acv data
  end
end
