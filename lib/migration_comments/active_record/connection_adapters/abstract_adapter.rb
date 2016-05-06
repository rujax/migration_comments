module MigrationComments::ActiveRecord::ConnectionAdapters
  module AbstractAdapter
    def set_table_comment(_table_name, _comment_text)
    end

    def set_column_comment(_table_name, _column_name, _comment_text)
    end

    def add_table_comment(*args)
      puts "'add_table_comment' is deprecated, and will be removed in future releases. Use 'set_table_comment' instead."

      set_table_comment(*args)
    end

    def add_column_comment(*args)
      puts "'add_column_comment' is deprecated, and will be removed in future releases. Use 'set_column_comment' instead."

      set_column_comment(*args)
    end

    def comments_supported?
      false
    end

    # SQLite style - embedded comments
    def inline_comments?
      false
    end

    # PostgreSQL style - comment specific commands
    def independent_comments?
      false
    end

    # Remove a comment on a table (if set)
    def remove_table_comment(table_name)
      set_table_comment(table_name, nil)
    end

    # Remove a comment on a column (if set)
    def remove_column_comment(table_name, column_name)
      set_column_comment(table_name, column_name, nil)
    end

    def retrieve_table_comment(_table_name)
      nil
    end

    def retrieve_column_comments(_table_name, *_column_names)
      {}
    end

    def retrieve_column_comment(table_name, column_name)
      retrieve_column_comments(table_name, column_name)[column_name]
    end
  end
end
