require 'wheelhouse/command-runner'
require 'wheelhouse/queries/server'

module Wheelhouse
  module Commands
    CONNSTRING = "sqlite://servers.sql"

    class Command
      def initialize(options)
        @options = options
      end
      attr_accessor :options

      def if_option(name)
        if options.has_key?(name.to_s)
          yield(options[name])
        end
      end
    end

    module Main
      class Defined < Command
        def initialize(config, options)
          @config = config
          super(options)
        end
        attr_reader :config

        def execute
          config.query_options = options || {}

          query = Wheelhouse::Queries::Server.new(CONNSTRING)
          if_option(:client){|client| query.client = client }
          if_option(:role){|role| query.role = role }
          if_option(:name){|name| query.name = name }
          if_option(:platform){|platform| query.platform = platform }

          runner = Wheelhouse::CommandRunner.new(query, config)
          runner.run
        end
      end
    end

    module Database
      class Migrate < Command
        def initialize
          @db_string  = CONNSTRING
          @directory = "migrations"
        end
        attr_accessor :db_string, :directory

        def execute
          require 'sequel/extensions/migration'

          Wheelhouse.log_at(Logger::DEBUG) do
            Sequel::Migrator.run(databases[db_string], directory)
          end
        end
      end
    end

    module Servers
      class Add < Command
        def initialize(source_io)
          @source_io = source_io
        end

        def execute
          require 'yaml'
          require 'wheelhouse/persisters/server'
          serverlist = Array(YAML.load(source_io.read))

          store = Wheelhouse::Persisters::Server.new(CONNSTRING)

          defaults = {:client => options[:client]}

          serverlist.each do |server|
            store.insert_or_update(defaults.merge(server))
          end
        end
      end

      class List < Command
        def execute
          require 'wheelhouse/queries/server'
          Wheelhouse::Queries::Server.new(CONNSTRING).print
        end
      end

      class Edit < Command
        def execute
          require 'yaml'
          require 'wheelhouse/persisters/server'
          require 'io/console'

          query = Wheelhouse::Queries::Server.new(CONNSTRING)

          if_option(:id){|server_id|
            query.server_id = server_id }
          if_option(:client){|client| query.client = client }
          if_option(:role){|role| query.role = role }
          if_option(:name){|name| query.name = name }
          if_option(:platform){|platform| query.platform = platform }

          unless query.to_a.length == 1
            puts "#{query.to_a.length} servers match #{query.constraint.inspect}"
            exit 1
          end

          server = query.first

          server_hash = server.to_hash
          server_id = server_hash.delete(:server_id)

          begin
            file = Tempfile.new('server', '.')
            file.write("# Edit this file to update the server\n")
            file.write(server_hash.to_yaml)
            file.close
            edit_shell = Caliph::Shell.new
            edit_shell.output_stream = File.new("/dev/null", "a")
            edit_shell.run(ENV['EDITOR'] || 'vim', file.path) do |cmd|
              cmd.redirect_stdin(IO.console.path)
              cmd.redirect_stdout(IO.console.path)
            end
            file.open
            new_hash = YAML.load(file.read).merge(:server_id => server_id)
            store = Wheelhouse::Persisters::Server.new(CONNSTRING)

            store.insert_or_update(new_hash)
          ensure
            edit_shell.output_stream.close
            file.unlink
          end
        end
      end
    end
  end
end
