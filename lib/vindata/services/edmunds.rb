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
      vinlookup = "#{base_url}vins/#{vin}"
      response = JSON.parse(RestClient.get vinlookup, {:params => {
        fmt: 'json',
        api_key: configuration[:edmunds][:api_key]
        }})

      # TODO: Check data validity here
      ret = {}
      ret[:make] = response['make']['niceName']
      if response['model']
        ret[:model] = response['model']['niceName']
      elsif response['years'].first['styles'].first['submodel']
        ret[:model] = response['years'].first['styles'].first['submodel']['modelName']
      end
      ret[:year] = response['years'][0]['year']
      ret[:edmunds] = response
      return ret
    # Indicates VIN request failed with Edmunds
    rescue RestClient::BadRequest => err
      return nil
    # Indicates VIN was not valid
    rescue RestClient::ResourceNotFound => err
      return nil
    end

    def recalls data
      if data[:edmunds] && data[:edmunds]['years'][0]
        year_id = data[:edmunds]['years'][0]['id']
      else
        # return nil unless data[:style_id]
        years_url = "https://api.edmunds.com/api/vehicle/v2/#{data[:make]}/#{data[:model]}"
        response = JSON.parse(RestClient.get years_url, {:params => {
          fmt: 'json',
          api_key: configuration[:edmunds][:api_key]
          }})
        year_id = response['years'].select{ |x| x['year'] == data[:year] }.first['id']
      end

      recall_url = 'https://api.edmunds.com/v1/api/maintenance/recallrepository/findbymodelyearid'
      recall_response = JSON.parse(RestClient.get recall_url, {:params => {
        modelyearid: year_id,
        fmt: 'json',
        api_key: configuration[:edmunds][:api_key]
        }})

      bulletin_url = 'https://api.edmunds.com/v1/api/maintenance/servicebulletinrepository/findbymodelyearid'
      bulletin_response = JSON.parse(RestClient.get bulletin_url, {:params => {
        modelyearid: year_id,
        fmt: 'json',
        api_key: configuration[:edmunds][:api_key]
        }})

      # TODO: Check data validity here

      return {
        edmunds: {
          recalls: recall_response,
          bulletins: bulletin_response
        }
      }
    # Indicates VIN request failed with Edmunds
    rescue RestClient::BadRequest => err
      return nil
    end

    def style_data data
      stylelookup = base_url + data[:make] + '/' + data[:model] + '/' + data[:year].to_s + '/styles'
      JSON.parse(RestClient.get stylelookup, {:params => {
        fmt: 'json',
        api_key: configuration[:edmunds][:api_key]
        }})
    end

    # Required Data:
    #   :make
    #   :model
    #   :year
    #   :mileage
    #   :zip
    def get_acv data

      info_is_present = data[:make] && data[:model] && data[:year]
      vin_is_present = data[:vin].present?
      condition_is_present = data[:condition].present?
      location_is_present = data[:mileage] && data[:zip]

      return nil unless (info_is_present || vin_is_present) &&
        location_is_present &&
        condition_is_present

      if vin_is_present
        car_details = details_by_vin data.delete(:vin)
        return nil unless car_details
        data.merge! car_details
      end

      # Get the style ID by vehicle make/model/year
      response = style_data data

      # TODO: Check data validity here

      acvlookup = 'https://api.edmunds.com/v1/api/tmv/tmvservice/calculateusedtmv'
      response = JSON.parse(RestClient.get acvlookup, {:params => {
        styleid: response['styles'][0]['id'],
        condition: data[:condition].to_s.capitalize,
        mileage: data[:mileage],
        zip: data[:zip],
        fmt: 'json',
        api_key: configuration[:edmunds][:api_key]
      }})

      # TODO: Check data validity here
      if response == nil || response['tmv'] == nil
        return nil
      else
        return {
          common: {
            retail: response['tmv']['totalWithOptions']['usedTmvRetail'],
            private_party: response['tmv']['totalWithOptions']['usedPrivateParty'],
            trade_in: response['tmv']['totalWithOptions']['usedTradeIn']
          },
          edmunds: response
        }
      end
    end
  end
end
