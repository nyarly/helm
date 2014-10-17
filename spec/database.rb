require 'wheelhouse'
require 'wheelhouse/persisters/server'
require 'wheelhouse/queries/server'

describe Wheelhouse, "database" do
  it "should store and retreive server records" do
    in_memory = "sqlite:/"
    app_config = Wheelhouse::Config.new(in_memory, "", ".")

    migrate_command = Wheelhouse::Commands::Database::Migrate.new(app_config, {})
    migrate_command.execute

    server_hash = {"name" => "a","client" => "b"}
    persister = Wheelhouse::Persisters::Server.new(in_memory)
    persister.insert_or_update(server_hash)

    query = Wheelhouse::Queries::Server.new(in_memory)
    query.client = server_hash["client"]

    server = query.first

    expect(server.name).to be == server_hash["name"]
    expect(server.server_id).not_to be_nil
  end
end
