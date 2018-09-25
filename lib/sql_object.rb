require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  def self.columns
    if @cols
      return @cols
    end
    columns = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL

    @cols = columns.first.map { |name| name.to_sym }
  end

  def self.finalize!
    self.columns.each do |col|
      define_method(col) do
        attributes[col]
      end
      define_method("#{col}=") do |value|
        attributes[col] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= "#{self}".to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL
    parse_all(results)
  end

  def self.parse_all(array)
    results.map do |obj|
      self.new(obj)
    end
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        #{self.finalize![0]} = ?
    SQL
    return nil if result.empty?
    self.new(result.first)
  end

  def self.find_by(params)
    keys = params.keys.map { |key| "#{key}= ?"}.join(" AND ")
    values = param.values
    result = DBConnection.execute(<<-SQL, *values)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        #{keys}
    SQL
    return nil if result.empty?
    self.new(result.first)
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name.to_sym)
      send("#{attr_name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    result = []
    self.class.columns.each do |col|
      result << send(col)
    end
    result
  end

  def insert
    col_names = (self.class.columns - [:id]).join(",")
    question_marks = []
    col_names.split(",").length.times do
      question_marks << "?"
    end
    vals = attribute_values[1..-1]
    question_marks = question_marks.join(",")


    DBConnection.execute(<<-SQL, *vals)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    send("id=", DBConnection.last_insert_row_id)
  end

  def update
    set_vals = (self.class.columns - [:id]).map { |col| "#{col} = ?" }.join(",")
    id = "#{self.class.columns.first} = ?"
    vals = attribute_values.rotate
    # debugger
    DBConnection.execute(<<-SQL, *vals)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_vals}
      WHERE
        #{id}
    SQL
  end

  def save
    if send(:id)
      update
    else
      insert
    end
  end
end
