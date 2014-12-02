require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    cols = DBConnection.execute2(<<-SQL)
    SELECT
      *
    FROM
      #{self.table_name}
    SQL
    cols.first.map(&:to_sym)
  end

  def self.finalize!
    methods = self.columns

    methods.each do |method|
      define_method(method) do
        self.attributes[method]
      end

      define_method("#{method}=".to_sym) do |obj|
        self.attributes[method] = obj
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.tableize
  end

  def self.str_hash_to_sym_hash(hash)
    sym_hash = Hash.new
    hash.each do |key,val|
      sym_hash[key.to_sym] = val
    end
    sym_hash
  end

  def self.all
    items = DBConnection.execute(<<-SQL)
    SELECT
      #{self.table_name}.*
    FROM
      #{self.table_name}
    SQL
    items = items.map { |item| self.str_hash_to_sym_hash(item) }
    self.parse_all(items)
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    item = DBConnection.execute(<<-SQL, id)
    SELECT
    #{self.table_name}.*
    FROM
    #{self.table_name}
    WHERE
    id = ?
    SQL
    return nil if item.empty?
    self.new(self.str_hash_to_sym_hash(item.first))
  end

  def initialize(params = {})
    cols = self.class.columns
    params.each do |param, val|
      raise "unknown attribute '#{param}'" unless cols.include?(param)
      self.send("#{param}=".to_sym, val)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |key| self.send(key) }
  end

  def insert
    cols = self.class.columns
    column_names = cols.join(",")
    question_marks = (["?"] * cols.size).join(",")
    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO
    #{self.class.table_name} (#{column_names})
    VALUES
    (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    cols = self.class.columns
    column_names = cols.map { |col| "#{col} = ?"}.join(",")
    DBConnection.execute(<<-SQL, *attribute_values)
    UPDATE
    #{self.class.table_name}
    SET
    #{column_names}
    WHERE
    id = #{self.id}
    SQL
  end

  def save
    if self.id.nil?
      insert
    else
      update
    end
  end
end
