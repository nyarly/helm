require 'helm/persister'
require 'helm/records/server'

module Helm
  module Persisters
    class Server < Persister
      def columns
        Records::Server.columns
      end

      def table_name
        :servers
      end
    end
  end
end
