require 'caliph'

module Helm
  class CommandRunner
    CommandExecution = Struct.new(:server, :result)

    def initialize(server_query, command_definition)
      @server_query, @command_definition = server_query, command_definition
      @completed = []
      @ran_any = false
    end

    attr_accessor :server_query, :command_definition, :shell

    def shell
      @shell ||= Caliph::Shell.new
    end

    def run
      start_run
      catch :fail do
        configured_query.each do |server|
          result = run_one(command_definition.command(server))
          execution = CommandExecution.new(server, result)
          collect(execution)
        end
      end
      finish_run
    end

    def configured_query
      command_definition.configure_query(server_query)
      server_query
    end

    def run_one(single)
      @ran_any = true
      shell.execute(single)
    end

    def start_run
      @ran_any = false
    end

    def finish_run
      warn "No servers found for #{server_query}!" unless @ran_any
      command_definition.all_results(@completed)
      return true
    end

    def collect(execution)
      @completed << execution
      command_definition.each_result(execution)
    end
  end
end
