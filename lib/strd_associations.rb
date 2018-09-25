require_relative 'search_queries'
require 'active_support/inflector'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    class_name.constantize.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @class_name = options[:class_name] || name.to_s.capitalize
    @foreign_key = options[:foreign_key] || "#{@class_name.underscore}_id".to_sym
    @primary_key = options[:primary_key] || :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @class_name = options[:class_name] || name.to_s.capitalize.singularize
    @foreign_key = options[:foreign_key] || "#{self_class_name}_id".underscore.to_sym
    @primary_key = options[:primary_key] || :id
  end
end

module Associatable
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)
    define_method(name) do
      options = self.class.assoc_options[name]
      foreign = self.send(options.foreign_key)
      model = options.model_class
      selected = model.where(id: foreign).first
    end
  end

  def has_many(name, options = {})
    obj = HasManyOptions.new(name, self, options)
    define_method(name) do
      foreign = obj.foreign_key
      model = obj.model_class
      selected = model.where(foreign => id)
    end
  end

  def assoc_options
    @assoc_options ||= {}
    @assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
end
