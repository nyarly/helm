require 'caliph/command-line-dsl'

module Wheelhouse
  class ServerCommand

    class << self
      def subclasses
        @subclasses ||= []
      end

      def inherited(sub)
        ServerCommand.subclasses << sub
      end

      def abstract
        @abstract = true
      end

      def abstract?
        !!@abstract
      end

      def valid_commands(quietly = false)
        valid = []
        ServerCommand.subclasses.each do |sub|
          next if sub.abstract?

          methods = sub.instance_methods(false)

          unless methods.include?(:name) and methods.include?(:command)
            unless quietly
              warn "ServerCommand subclass #{sub.name} isn't abstract and doesn't define :name and :command"
              a_method = sub.instance_method(methods.first)
              warn "  (appears to be defined in #{a_method.source_location.first})"
            end
            next
          end

          valid << sub
        end
        valid
      end
    end

    def valid?
      true
    end

    def desc
      ""
    end
    alias description desc

    def required_options
      []
    end
    alias scope_options required_options

    attr_accessor :query_options

    def configure_query(query)
    end

    def each_result(execution)
      format_result(execution)
      if execution.result.exit_code != 0
        throw :fail
      end
    end

    def all_results(results)
    end

    def format_result(execution)
      result = execution.result
      server = execution.server

      puts "#{server.name} (#{server.public_ip_address})"
      puts "#{result.command.string_format} => #{result.exit_code}"
      puts result.format_streams
      puts
    end

    include Caliph::CommandLineDSL

    def ssh(server, *command, &block)
      cmd("ssh") do |command|
        command.options << "-o BatchMode=yes"
        command.options << "-i " + server.ssh_key_name unless server.ssh_key_name.nil?
        #command.options << "-l " + server.connect_as unless
        #server.connect_as.nil?
        # XXX need to add 'connect_as'
        #command.options << "-p " + server.port unless server.ssh_port.nil?
        # XXX need to add "ssh_port"
        command.options << server.public_dns_name || server.public_ip_address
      end - escaped_command(*command, &block)
    end
  end

  module Persistent
    def each_result(result)
      format_results(result)
    end
  end

  module Picky
    def all_results(results)
      if results.any?{|execution| execution.result.exit_code != 0}
        raise "Command failed!\n  #{
          results.select{|execution| execution.result.exit_code != 0
        }.map{|exec| exec.result.inspect}.join("  \n")
        }"
      end
    end
  end
end
