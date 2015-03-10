require 'vindata/services/base'
require 'savon'

module Savon
  class Client
    def get_request_xml operation_name, locals
      Savon::Builder.new(operation_name, @wsdl, @globals, locals).pretty
    end
  end
end

module VinData::Services
  class Nada < Base

    def initialize
      # get_token
    end

    def name
      'NADA'
    end

    def base_url
      nil
    end

    def get_token
      # we don't want to get the token every time
      # return @token if @token.present?

      fail 'NADA requires username and password' unless configuration[:username].present? &&
                                                        configuration[:password].present?

      wsdl_path = File.expand_path(File.join(File.dirname(__FILE__), '../wsdls/ProdSecureLogin.wsdl'))
      # do auth login to get token
      client = Savon.client(
        wsdl: wsdl_path,
        raise_errors: true,
        log_level: :info,
        pretty_print_xml: true,
        env_namespace: :soap,
        namespace_identifier: :web
      )
      data = client.call(:get_token,
                         message: { 'tokenRequest' =>
                                    { 'Username' => configuration[:username],
                                      'Password' => configuration[:password]
                                    }
                                  }
                        )
      @token = data.to_hash[:get_token_response][:get_token_result]
    end

    def get_client
      wsdl_path = File.expand_path(
                                    File.join(File.dirname(__FILE__),
                                    '../wsdls/ProdVehicle.wsdl')
                                  )
      # do auth login to get token
      client = Savon.client(
        wsdl: wsdl_path,
        raise_errors: true,
        log_level: :info,
        pretty_print_xml: true,
        env_namespace: :soap,
        namespace_identifier: :web
      )
      client
    end

    def get_region_by_state(state)
      client = get_client
      data = client.call(:get_region_by_state_code,
                         message: { 'l_Request' => { 'Token' => get_token,
                                                     'Period' => 0,
                                                     'VehicleType' => 'UsedCar',
                                                     'StateCode' => state
                                                   }
                                  }
                        )
      data.to_hash[:get_region_by_state_code_response][:get_region_by_state_code_result]
    end

    def details_by_vin(vin)
      token = get_token
      client = get_client
      data = client.call(:get_vehicles,
                         message: { 'vehicleRequest' =>
                                      { 'Token' => token,
                                        'Period' => 0,
                                        'VehicleType' => 'UsedCar',
                                        'Vin' => vin
                                      }
                                  }
                        )
      data.to_hash[:get_vehicles_response][:get_vehicles_result][:vehicle_struc].first
    end

    # Required Data:
    #   :vin
    #   :state
    #   :mileage
    def get_acv(data)
      return nil unless data[:vin] && data[:state] && data[:mileage]

      token = get_token

      region_id = get_region_by_state data[:state]

      client = get_client

      begin
        data = client.call(:get_default_vehicle_and_value_by_vin,
                           message: { 'vehicleRequest' =>
                                        { 'Token' => token,
                                          'Period' => 0,
                                          'VehicleType' => 'UsedCar',
                                          'Vin' => data[:vin],
                                          'Region' => region_id,
                                          'Mileage' => data[:mileage]
                                        }
                                    }
                          )
        data = data.to_hash[:get_default_vehicle_and_value_by_vin_response][:get_default_vehicle_and_value_by_vin_result]
        return {
          common: {
            retail: data[:retail_plus_vin_acc_mileage],
            trade_in: data[:trade_in_plus_vin_acc_mileage]
          },
          nada: data
        }

      rescue Savon::SOAPFault => error
        return false if error.message.include? 'No vehicle found'
        raise error.message
      end
    end
  end
end
