require 'wheelhouse/record'

module Wheelhouse
  module Records
    Server = Record.subclass(
      :server_id,
      :platform,
      :id_from_platform,
      :name,
      :client,
      :private_dns_name,
      :public_dns_name,
      :private_ip_address,
      :public_ip_address,
      :ssh_key_name,
      :architecture,
      :launch_time
    ) do
      def name
        self[:name] || [self[:platform], self[:id_from_platform]].join(":")
      end
    end
  end
end
