require_relative 'db_connection'
require_relative 'sql_object'
module Searchable
  def where(params)
    if params.is_a?(Hash)
      keys = params.keys.map { |key| "#{key}= ?"}.join(" AND ")
      vals = params.values
    else
      keys = params
    end
    result = DBConnection.execute(<<-SQL, *vals)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{keys}
    SQL
    self.parse_all(result)
  end
end

class SQLObject
  extend Searchable
end

