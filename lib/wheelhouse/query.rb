require 'wheelhouse'

module Wheelhouse
  class Query
    include Enumerable

    def initialize(conn_string)
      @db = Wheelhouse.databases[conn_string]
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
end
