require 'helm/query'
require 'helm/records/server'

module Helm
  module Queries
    class Server < Query
      attr_accessor :server_id, :client, :name, :role, :platform, :id_from_platform

      def to_s
        nil_attrs = constraint_attrs.reject{|attr| constraint_hash.has_key?(attr) }
        "Servers query: #{constraint_hash.inspect} (not set: #{nil_attrs.inspect})"
      end

      def inspect
        "<#{self.class.name}:#{"%0x" % object_id} #{constraint.select_sql rescue "<?sql?>"}>"
      end

      def constraint_attrs
        [:server_id, :client, :name, :role, :platform, :id_from_plaform]
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
end
