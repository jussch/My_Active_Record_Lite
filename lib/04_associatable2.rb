require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]


      so_tn = source_options.table_name
      to_tn = through_options.table_name
      items = DBConnection.execute(<<-SQL,self.send(through_options.foreign_key))
        SELECT
          #{so_tn}.*
        FROM
          #{to_tn}
        JOIN
          #{so_tn}
        ON
          #{to_tn}.#{source_options.foreign_key} = #{so_tn}.#{source_options.primary_key}
        WHERE
          #{to_tn}.#{through_options.primary_key} = ?
      SQL

      items = items.map { |item| SQLObject.str_hash_to_sym_hash(item) }
      items.map { |result| source_options.model_class.new(result) }.first
    end
  end
end
