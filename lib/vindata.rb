# External gems
require 'rest_client'

# Internal files
require 'vindata/configuration'
# TODO: Generalize the services require process
require 'vindata/services/edmunds'

module VinData
  def self.testoutput
    'VinData working'
  end

  def self.lookup_by_vin vin
    edmunds = Services::Edmunds.new
    edmunds.lookup_by_vin '1N4AL3APCDNDASDFADF'
  end
end
