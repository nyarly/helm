require 'valise'
require 'sequel'
require 'logger'
require 'wheelhouse/application'
require 'wheelhouse/cli'
require 'wheelhouse/server-command'

module Wheelhouse
  class << self
    def logger
      @logger ||= Logger.new($stderr).tap do |logger|
        logger.level = Logger::ERROR
      end
    end

    def databases
      @databases = Hash.new do |hash, conn_string|
        hash[conn_string] = Sequel::connect(conn_string, :logger => logger).tap do |db|
          db.extension(:pretty_table)
        end
      end
    end

    def log_at(level)
      begin
        old_level, logger.level = logger.level, level
        yield
      ensure
        logger.level = old_level
      end
    end

    def check_db(db_string, directory)
      require 'sequel/extensions/migration'

      unless Sequel::Migrator.is_current?(databases[db_string], directory)
        warn "Your servers database is out of date. You should run #$0 db update."
      end
    end

    def valise
      @valise ||= Valise.define do
        ro from_here(%w{.. default_configuration}, up_to("lib"))
      end
    end

    def commands_valise
      @commands_valise ||= valise.sub_set("commands")
    end

    def load_commands
      commands_valise.glob("*.rb") do |file|
        require file.full_path
      end
      ServerCommand.valid_commands.each do |command_class|
        CLI::Main.define_from(command_class.new)
      end
    end
  end
end
