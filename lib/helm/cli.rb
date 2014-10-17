require 'helm'
require 'thor'

module Helm
  Config = Struct.new(:connstring, :editor, :tempdir)

  def self.config
    Config.new("sqlite://servers.sql", "vim", ".")
  end

  module CLI
    class DB < Thor
      include Commands::Database

      desc "update", "Update the servers database schema"
      def update
        Migrate.new(Helm.config, options).execute
      end
    end

    class Server < Thor
      include Commands::Servers

      desc "add", "Add a list of servers described in YAML from STDIN"
      option :client, :banner => "Client name"
      def add
        Add.new(Helm.config, options, $stdin).execute
      end

      desc "list", "List servers that Helm knows about"
      def list
        puts List.new(Helm.config, options).execute
      end

      desc "edit", "Edit the details of particular servers"
      method_option :id
      def edit
        Edit.new(Helm.config, options).execute
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
        def define_from(command_config)
          desc command_config.name.to_s, command_config.description
          command_config.scope_options.each do |name|
            option name, :required => true
          end

          define_method command_config.name do |*args|
            command = Commands::Main::Defined.new(Helm.config, options, command_config)
            command.execute(*args)
          end
        end
      end

      def help(task = nil, subcommand=false)
        super

        shell.say "Commands are loaded from:"
        shell.say Helm.commands_valise.to_s
      end
    end
  end
end
