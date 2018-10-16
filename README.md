# Welcome to DBSeek

#### A lightweight Ruby ORM based on ActiveRecord.

## Getting Started: 

Step 1:

- Open up the DBSeek folder in your favorite IDE
    
- Add your db file to the folder

Step 2:

- Inside the lib folder, open up the file `db_connection.rb`

- Change the `String` value for lines 5 & 6 to the name of your db file.
```ruby
    SQL_FILE = File.join(ROOT_FOLDER, 'your_db_file_here.sql')
    DB_FILE = File.join(ROOT_FOLDER, 'your_db_file_here.db') 
```
- And you're ready to go!

## Important Methods:

- ### `Searchable#where`
    -   **In a separate module, I defined a method that takes an argument in the form of a `String` or `Hash` and generates a sql querry based on those params.**
```ruby
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
```
- ### `SQLObject::parse_all`
    -   **Iterates through an array of `Hash`es returned from a query and creates new instances of SQLObject out of them**
    ```ruby
    def self.parse_all(array)
        results.map do |obj|
            self.new(obj)
        end
    end
    ```

- ### `SQLObject::find`
    -   **takes in an id parameter and returns a SQLObject with the given id**
```ruby
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
```
- ### `SQLObject#insert`
    - **dynamically generates a SQL querry for inserting value into specific collumns**
```ruby
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
```
- ### `Associatable#belongs_to`
    -   **takes in the association name argument and an options `Hash` and creates a `BelongsToOptions` object based on the arguments passed in**
```ruby
    def belongs_to(name, options = {})
        self.assoc_options[name] = BelongsToOptions.new(name, options)
        define_method(name) do
            options = self.class.assoc_options[name]
            foreign = self.send(options.foreign_key)
            model = options.model_class
            selected = model.where(id: foreign).first
        end
    end

    def assoc_options
        @assoc_options ||= {}
        @assoc_options
    end

    class BelongsToOptions < AssocOptions
        def initialize(name, options = {})
            @class_name = options[:class_name] || name.to_s.capitalize
            @foreign_key = options[:foreign_key] || "#{@class_name.underscore}_id".to_sym
            @primary_key = options[:primary_key] || :id
        end
    end
```