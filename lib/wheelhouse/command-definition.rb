module Wheelhouse
  class CommandDefinition
    SCOPE_TO_OPTIONS = {
      "all" => [],
      "client" => [:client],
      "role" => [:client, :role],
      "name" => [:client, :name]
    }
    attr_accessor :name, :description, :scope
    attr_reader :action

    alias desc= description=

      def initialize(name=nil, scope=nil, desc=nil)
        @name = name
        @description = desc
        @scope = scope
      end

    def action(&block)
      if block_given?
        @action = block
      else
        @action
      end
    end

    def valid?
      return false if @name.nil?
      return false unless SCOPE_TO_OPTIONS.keys.include? @scope.to_s
      return false if @action.nil?
      return true
    end

    def scope_options
      SCOPE_TO_OPTIONS[@scope.to_s]
    end
  end
end
require 'wheelhouse/single-command'
require 'erb'

module Wheelhouse
  class CommandDefinition
    include Enumerable

    def initialize(command_template)
      @template = ::ERB::new(decorate(command_template))
    end

    def decorate(template)
      template
    end

    def for_server(server)
      SingleCommand.new(server, self)
    end

    def render(server)
      @template.result(server.instance_eval{ binding })
    end
  end

  class SSHCommandDefinition < CommandDefinition
    def decorate(template)
      "ssh -i ~/.ssh/1f1r_rsa <%= public_dns_name || public_ip_address %> '#{template}'"
    end
  end
end
