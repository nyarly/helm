module Helm
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
        klass = Class.new(self, &block)
        columns = columns.sort
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
      @row.keys | @values.keys
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

    def to_hash
      Hash[ keys.map{|key| [key, self[key]]}]
    end

    def to_yaml
      to_hash.to_yaml
    end
  end
end
