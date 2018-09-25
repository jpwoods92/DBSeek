require_relative 'strd_associations'

module Associatable

  def has_one_through(name, through_name, source_name)
    obj = self
    define_method(name) do
      through_options = obj.assoc_options[through_name]
      model = through_options.model_class
      source_options = model.assoc_options[source_name]
      
      through_table = through_options.table_name
      source_table = source_options.table_name

      source_f_key = source_options.foreign_key
      source_p_key = source_options.primary_key

      through_p_key = through_options.primary_key
      through_f_key = through_options.foreign_key

      vals = self.send(through_f_key)

      results = DBConnection.execute(<<-SQL, vals)
        SELECT
          #{source_table}.*
        FROM
          #{through_table}
        JOIN
          #{source_table} 
        ON 
          #{through_table}.#{source_f_key} = #{source_table}.#{source_p_key}
        WHERE
          #{through_table}.#{through_p_key} = ?
      SQL
      return source_options.model_class.parse_all(results).first
    end
  end
end
