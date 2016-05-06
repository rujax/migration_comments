module MigrationComments::ActiveRecord::ConnectionAdapters::AbstractAdapter
  module SchemaCreation
    def self.included(base)
      base.send :prepend, ColumnOptionsWithMigrationComments
      base.send :prepend, AddColumnOptionsWithMigrationComments
      base.send :prepend, VisitTableDefinitionWithMigrationComments
      base.send :prepend, VisitColumnDefinitionWithMigrationComments
    end

    module ColumnOptionsWithMigrationComments
      def column_options(o)
        column_options = o.primary_key? ? {} : super(o)

        column_options[:comment] = o.comment.comment_text if o.comment

        column_options
      end
    end

    module AddColumnOptionsWithMigrationComments
      def add_column_options!(sql, options)
        sql = super(sql, options)

        if options.keys.include?(:comment) && !@conn.independent_comments?
          sql << MigrationComments::ActiveRecord::ConnectionAdapters::CommentDefinition.new(@conn, nil, nil, options[:comment]).to_sql
        end

        sql
      end
    end

    module VisitTableDefinitionWithMigrationComments
      def visit_TableDefinition(o)
        if @conn.inline_comments?
          create_sql = "CREATE#{' TEMPORARY' if o.temporary} TABLE "
          create_sql << "#{quote_table_name(o.name)}#{o.table_comment} ("
          create_sql << o.columns.map { |c| accept c }.join(', ')
          create_sql << ") #{o.options}"

          create_sql
        else
          super(o)
        end
      end
    end

    module VisitColumnDefinitionWithMigrationComments
      def visit_ColumnDefinition(o)
        if @conn.inline_comments?
          sql_type = type_to_sql(o.type.to_sym, o.limit, o.precision, o.scale)

          column_sql = "#{quote_column_name(o.name)} #{sql_type}"

          add_column_options!(column_sql, column_options(o))

          column_sql
        else
          super(o)
        end
      end
    end
  end
end
