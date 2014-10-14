require 'wheelhouse/persister'
require 'wheelhouse/records/server'

module Wheelhouse
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
