require 'mattock/command-line'
require 'sequel'
require 'erb'
require 'logger'

module ClusterMan
  def self.logger
    @logger ||= Logger.new($stderr).tap do |logger|
      logger.level = Logger::ERROR
    end
  end

  def self.databases
    @databases = Hash.new do |hash, conn_string|
      hash[conn_string] = Sequel::connect(conn_string, :logger => logger).tap do |db|
        db.extension(:pretty_table)
      end
    end
  end

  def self.log_at(level)
    begin
      old_level, logger.level = logger.level, level
      yield
    ensure
      logger.level = old_level
    end
  end

  def self.check_db(db_string, directory)
    require 'sequel/extensions/migration'

    unless Sequel::Migrator.is_current?(databases[db_string], directory)
      warn "Your servers database is out of date. You should run #$0 db update."
    end
  end

  def self.migrate(db_string, directory)
    require 'sequel/extensions/migration'

    log_at(Logger::DEBUG) do
      Sequel::Migrator.run(databases[db_string], directory)
    end
  end

  class Record
    class << self
      attr_accessor :columns

      def types
        @types ||= {}
      end

      def with_columns(*columns)
        types[columns.sort] || subclass(*columns)
      end

      def subclass(*columns, &block)
        columns = columns.sort
        klass = Class.new(self, &block)
        klass.columns = columns

        columns.each do |column|
          klass.column_accessor(column)
        end
        types[columns] ||= klass
      end

      def column_accessor(name)
        unless instance_methods(false).include?(name)
          define_method name do
            @values[name]
          end
        end

        write_method = "#{name}="
        unless instance_methods(false).include?(write_method)
          define_method write_method do |value|
            @values[name] = value
          end
        end
      end
    end

    def [](key)
      @values[key]
    end

    def []=(key, value)
      @values[key] = value
    end

    def keys
      @rows.keys | @values.keys
    end

    def initialize(row)
      @row = row
      @values = Hash.new do |h, k|
        @row[k]
      end
    end

    def changed
      @values.keys
    end
  end

  module Records
    Server = Record.subclass(
      :server_id,
      :platform,
      :id_from_platform,
      :name,
      :client,
      :private_dns_name,
      :public_dns_name,
      :private_ip_address,
      :public_ip_address,
      :ssh_key_name,
      :architecture,
      :launch_time
    ) do
      def name
        self[:name] || [self[:platform], self[:id_from_platform]].join(":")
      end
    end
  end

  class Persistence
    class Storer

    end

    class Server < Storer
      def initialize(db_string)
        @db = ClusterMan.databases[db_string]
      end

      def columns
        Records::Server.columns
      end

      def slice(hash)
        Hash[ columns.zip(
          hash.values_at(*columns).zip(hash.values_at(*(columns.map(&:to_s)))
                                      ).map{|sym_val, str_val| sym_val || str_val }) ]
      end

      def table_name
        :servers
      end

      def dataset
        @db[table_name]
      end

      def insert_or_update(row)
        dataset.replace(slice(row))
      end
    end
  end

  class Query
    include Enumerable

    def initialize(conn_string)
      @db = ClusterMan.databases[conn_string]
    end

    attr_reader :db
    attr_accessor :result_class

    def constraint
      @constraint ||= @db
    end

    def print
      constraint.print
    end

    def each
      constraint.select(*result_class.columns).each do |row|
        yield result_class.new(row)
      end
    end
  end

  module Queries
    class Server < Query
      attr_accessor :client, :name, :role, :platform, :id_from_platform

      def to_s
        nil_attrs = constraint_attrs.reject{|attr| constraint_hash.has_key?(attr) }
        "Servers query: #{constraint_hash.inspect} (not set: #{nil_attrs.inspect})"
      end

      def inspect
        "<#{self.class.name}:#{"%0x" % object_id} #{constraint.select_sql rescue "<?sql?>"}>"
      end

      def constraint_attrs
        [:client, :name, :role, :platform, :id_from_plaform]
      end

      def constraint_hash
        @constraint_hash ||= constraint_attrs.each_with_object({}) do |attr, hash|
          val = instance_variable_get("@#{attr}")
          hash[attr] = val unless val.nil?
        end
      end

      def constraint
        @constraint ||= @db[:servers].where(constraint_hash)
      end

      def result_class
        Records::Server
      end
    end
  end

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

  class SingleCommand
    def initialize(server, command)
      @server, @command = server, command
    end
    attr_accessor :result
    attr_reader :server

    def to_s
      "#{server.name}: #{rendered} => #{status}"
    end

    def status
      if @result
        "\n" + @result.format_streams.gsub(/^/m,"  ")
      else
        "[unfinished]"
      end
    end

    def rendered
      @rendered ||= @command.render(server)
    end
  end

  class CommandRunner
    def initialize
      @completed = []
      @ran_any = false
    end

    attr_accessor :server_query, :command_definition

    def run
      start_run
      catch :fail do
        server_query.each do |server|
          run_one(command_definition.for_server(server))
        end
      end
      finish_run
    end

    def run_one(single)
      @ran_any = true
      command = Mattock::CommandLine.new(single.rendered)
      single.result = command.execute
      collect(single)
    end

    def start_run
      @ran_any = false
    end

    def finish_run
      warn "No servers found for #{server_query}!" unless @ran_any
      return true
    end

    def collect(execution)
      @completed << execution
      each_result(execution)
    end

    def each_result(execution)
      puts execution
      if execution.result.exit_code != 0
        throw :fail
      end
    end
  end

  class PersistentRunner < CommandRunner
    def run_one(single)
      catch :fail do
        super
      end
    end
  end

  class PersistentPickyRunner < PersistentRunner
    def finish_run
      if @completed.any?{|execution| execution.result.exit_code != 0}
        raise "Command failed!\n  #{
          @completed.select{|execution| execution.result.exit_code != 0
        }.map{|exec| exec.result.inspect}.join("  \n")
        }"
      end
      super
    end
  end

  class PersistentPermissiveRunner < PersistentRunner
  end

  class AbandonPickyRunner < CommandRunner
    def finish_run
      if @completed.any?{|execution| execution.result.exit_code != 0}
        raise "Command failed!"
      end
      super
    end
  end

  class AbandonPermissiveRunner < CommandRunner
  end

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
