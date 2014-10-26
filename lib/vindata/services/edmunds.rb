require 'vindata/services/base'

module VinData::Services
  class Edmunds < Base
    def name
      'Edmunds'
    end

    def base_url
      'https://api.edmunds.com/api/vehicle/v2/'
    end

    def details_by_vin vin
      # Lookup vehicle make/model/year by VIN
      vinlookup = base_url + 'vins/'+vin
      response = JSON.parse(RestClient.get vinlookup, {:params => {
        fmt: 'json',
        api_key: configuration[:api_key]
        }})

      # TODO: Check data validity here

      return {
        make: response['make']['niceName'],
        model: response['model']['niceName'],
        year: response['years'][0]['year']
      }
    end

    # Required Data:
    #   :make
    #   :model
    #   :year
    #   :mileage
    #   :zip
    def get_acv data
      # TODO: Make sure all proper data was passed

      # Get the style ID by vehicle make/model/year
      stylelookup = base_url + data[:make] + '/' + data[:model] + '/' + data[:year].to_s + '/styles'
      response = JSON.parse(RestClient.get stylelookup, {:params => {
        fmt: 'json',
        api_key: configuration[:api_key]
        }})

      # TODO: Check data validity here

      acvlookup = 'https://api.edmunds.com/v1/api/tmv/tmvservice/calculateusedtmv'
      response = JSON.parse(RestClient.get acvlookup, {:params => {
        styleid: response['styles'][0]['id'],
        condition: 'Clean',
        mileage: data[:mileage],
        zip: data[:zip],
        fmt: 'json',
        api_key: configuration[:api_key]
        }})

      # TODO: Check data validity here

      return {
        retail: response['tmv']['nationalBasePrice']['usedTmvRetail'],
        private_party: response['tmv']['nationalBasePrice']['usedPrivateParty'],
        trade_in: response['tmv']['nationalBasePrice']['usedTradeIn']
      }
    end
  end
end
