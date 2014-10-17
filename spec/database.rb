require 'helm'
require 'helm/persisters/server'
require 'helm/queries/server'

describe Helm, "database" do
  it "should store and retreive server records" do
    in_memory = "sqlite:/"
    app_config = Helm::Config.new(in_memory, "", ".")

    migrate_command = Helm::Commands::Database::Migrate.new(app_config, {})
    migrate_command.execute

    server_hash = {"name" => "a","client" => "b"}
    persister = Helm::Persisters::Server.new(in_memory)
    persister.insert_or_update(server_hash)

    query = Helm::Queries::Server.new(in_memory)
    query.client = server_hash["client"]

    server = query.first

    expect(server.name).to be == server_hash["name"]
    expect(server.server_id).not_to be_nil
  end
end
