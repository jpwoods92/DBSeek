class AttrAccessorObject
  def self.attr_accessor(*names)
    names.each do |name|
      define_method("#{name}=") do |arg|
        self.instance_variable_set("@#{name}", arg)
      end
    end
    names.each do |name|
      define_method(name) do
        self.instance_variable_get("@#{name}")
      end
    end
  end

end
