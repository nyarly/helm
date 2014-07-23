Sequel::migration do
  change do
    create_table :aws_ec2_attributes do
      foreign_key :server_id
      string :availability_zone
      string :image_id
    end
  end
end
