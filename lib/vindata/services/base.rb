module VinData
  module Services
    class Base
      def initialize
        @cache = nil
      end

      # Human readable name of this service
      def name
        fail
      end

      # Base URL of the API to query
      def base_url(query)
        fail
      end

      def details_by_vin vin
        fail
      end

      def configuration
        VinData.config
      end
    end
  end
end
