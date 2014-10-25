require 'vindata/services/base'

module VinData::Services
  class Edmunds < Base
    def name
      'Edmunds'
    end

    def base_url
      'https://api.edmunds.com/api/vehicle/v2/'
    end

    def lookup_by_vin vin
      squishvin = vin[0..7]+vin[9..10]
      squishlookup = base_url + 'squishvins/'+squishvin
      response = RestClient.get squishlookup, {:params => {
        fmt: 'json',
        api_key: configuration[:api_key]
        }}
      ap response
    end
  end
end
