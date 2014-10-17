require 'helm'

module Helm
  class Persister
    def initialize(db_string)
      @db = Helm.databases[db_string]
    end
    attr_accessor :db

    def slice(hash)
      Hash[
        columns.zip(
          hash.values_at(*columns).zip(
            hash.values_at(*(columns.map(&:to_s)))
      ).map{|sym_val, str_val| sym_val || str_val })
      ]
    end

    def dataset
      @db[table_name]
    end

    def insert_or_update(row)
      dataset.replace(slice(row))
    end
  end
end
