require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    clause = params.keys.map do |key|
      "#{key} = ?"
    end.join(" AND ")
    items = DBConnection.execute(<<-SQL,*params.values)
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      #{clause}
    SQL
    items = items.map { |item| self.str_hash_to_sym_hash(item) }
    self.parse_all(items)
  end
end

class SQLObject
  extend Searchable
end
