Sequel::migration do
  change do
    create_table :servers do
      primary_key :server_id
      string :platform, :null => false
      string :id_from_platform
      string :name
      string :client
      string :private_dns_name
      string :public_dns_name
      string :private_ip_address
      string :public_ip_address
      string :architecture
      string :ssh_key_name
      timestamp :launch_time
    end
  end
end
