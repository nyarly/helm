Sequel::migration do
  change do
    alter_table :servers do
      add_unique_constraint([:platform, :id_from_platform])
    end
  end
end
