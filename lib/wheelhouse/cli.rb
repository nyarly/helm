require 'wheelhouse'
require 'thor'

module Wheelhouse
  module CLI
    class DB < Thor
      include Commands::Database

      desc "update", "Update the servers database schema"
      def update
        Migrate.new(options).execute
      end
    end

    class Server < Thor
      include Commands::Servers

      desc "add", "Add a list of servers described in YAML from STDIN"
      option :client, :banner => "Client name"
      def add
        Add.new($stdin,options).execute
      end

      desc "list", "List servers that Wheelhouse knows about"
      def list
        puts List.new(options).execute
      end

      desc "edit", "Edit the details of particular servers"
      method_option :id
      def edit
        Edit.new(options).execute
      end
    end

    class Main < Thor
      desc "db SUBCOMMAND", "server database maintenance tasks"
      subcommand "db", DB

      desc "server SUBCOMMAND", "server listing tasks"
      subcommand "server", Server

      class_option :client
      class_option :name
      class_option :role

      class << self
        def required_options(*options)
          options.each do |name|
            option name, :required => true
          end
        end
        alias required_option required_options

        def define_from(config)
          desc config.name.to_s, config.description
          config.scope_options.each do |option|
            required_option option
          end

          define_method config.name do
            Commands::Main::Defined.new(config, options).execute
          end
        end
      end

      def help(task = nil, subcommand=false)
        super

        shell.say "Commands are loaded from:"
        shell.say Wheelhouse.commands_valise.to_s
      end
    end
  end
end
