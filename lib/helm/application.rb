require 'helm/command-runner'
require 'helm/queries/server'

module Helm
  module Commands
    class Command
      def initialize(app_config, options)
        @app_config = app_config
        @options = options
      end
      attr_accessor :app_config, :options

      def if_option(name)
        if options.has_key?(name.to_s)
          yield(options[name])
        end
      end
    end

    module Main
      class Defined < Command
        def initialize(app_config, options, config)
          @config = config
          super(app_config, options)
        end
        attr_reader :config

        def execute
          config.query_options = options || {}

          query = Helm::Queries::Server.new(app_config.connstring)
          if_option(:client){|client| query.client = client }
          if_option(:role){|role| query.role = role }
          if_option(:name){|name| query.name = name }
          if_option(:platform){|platform| query.platform = platform }

          runner = Helm::CommandRunner.new(query, config)
          runner.run
        end
      end
    end

    module Database
      class Migrate < Command
        def initialize(app_config, options)
          @directory = "migrations"
          super
        end
        attr_accessor :db_string, :directory

        def execute
          require 'sequel/extensions/migration'

          Helm.log_at(Logger::DEBUG) do
            Sequel::Migrator.run(Helm.databases[app_config.connstring], directory)
          end
        end
      end
    end

    module Servers
      class Add < Command
        def initialize(app_config, options, source_io)
          @source_io = source_io
          super(app_config, options)
        end

        def execute
          require 'yaml'
          require 'helm/persisters/server'
          serverlist = Array(YAML.load(source_io.read))

          store = Helm::Persisters::Server.new(app_config.connstring)

          defaults = {:client => options[:client]}

          serverlist.each do |server|
            store.insert_or_update(defaults.merge(server))
          end
        end
      end

      class List < Command
        def execute
          require 'helm/queries/server'
          Helm::Queries::Server.new(app_config.connstring).print
        end
      end

      class Edit < Command
        def edit_tempfile(file)
          require 'io/console'

          edit_shell = Caliph::Shell.new
          edit_shell.output_stream = File.new("/dev/null", "a")
          edit_shell.run(ENV['EDITOR'] || app_config.editor, file.path) do |cmd|
            cmd.redirect_stdin(IO.console.path)
            cmd.redirect_stdout(IO.console.path)
          end
        ensure
          edit_shell.output_stream.close
        end

        def server_query
          query = Helm::Queries::Server.new(app_config.connstring)

          if_option(:id){|server_id| query.server_id = server_id }
          if_option(:client){|client| query.client = client }
          if_option(:role){|role| query.role = role }
          if_option(:name){|name| query.name = name }
          if_option(:platform){|platform| query.platform = platform }

          query
        end

        def put_server_record_in_file(query, file)
          server = query.first
          server_hash = server.to_hash

          server_id = server_hash.delete(:server_id)

          file.write("# Edit this file to update the server\n")
          file.write(server_hash.to_yaml)
          file.close

          return server_id
        end

        def save_server_record_to_database(server_id, file)
          file.open
          new_hash = YAML.load(file.read).merge(:server_id => server_id)

          store = Helm::Persisters::Server.new(app_config.connstring)
          store.insert_or_update(new_hash)
        end

        def execute
          require 'yaml'
          require 'helm/persisters/server'

          query = server_query

          unless query.to_a.length == 1
            puts "#{query.to_a.length} servers match #{query.constraint.inspect}"
            exit 1
          end

          begin
            file = Tempfile.new('server', app_config.tempdir)

            server_id = put_server_record_in_file(query, file)

            edit_tempfile(file)

            save_server_record_to_database(server_id, file)
          ensure
            file.unlink if file
          end
        end
      end
    end
  end
end
