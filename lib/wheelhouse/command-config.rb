require 'wheelhouse/command-definition'
require 'wheelhouse/command-runner'
require 'wheelhouse/queries/server'

module Wheelhouse
  class CommandConfig
    attr_accessor :finish_all, :must_succeed

    def self.go!(db)
      cmd = new(db)

      yield cmd

      cmd.enact
    end

    def initialize(db)
      @db = db
      @finish_all = true
      @must_succeed = true
    end

    def servers(params)
      @query_params = params
    end

    def run(template)
      @command = CommandDefinition.new(template)
    end

    def ssh(template)
      @command = SSHCommandDefinition.new(template)
    end

    def finish_all!
      @finish_all = true
    end

    def fail_fast!
      @finish_all = false
    end

    def must_succeed!
      @must_succeed = true
    end

    def ignore_failures!
      @must_succeed = false
    end

    def runner_class
      case [@finish_all, @must_succeed]
      when [true, true]
        PersistentPickyRunner
      when [true, false]
        PersistentPermissiveRunner
      when [false, true]
        AbandonPickyRunner
      when [false, false]
        AbandonPermissiveRunner
      end
    end

    def enact
      query = Queries::Server.new(@db)
      query.client = @query_params[:client]
      runner = runner_class.new
      runner.server_query = query
      runner.command_definition = @command
      runner.run
    end
  end
end
