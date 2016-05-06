module MigrationComments::ActiveRecord::ConnectionAdapters
  module SQLiteAdapter
    include AbstractSQLiteAdapter

    def self.included(base)
      base.send :prepend, ColumnsWithMigrationComments
      base.send :prepend, CopyTableWithMigrationComments
    end

    module ColumnsWithMigrationComments
      def columns(table_name, name = nil)
        cols = super(table_name, name)

        comments = retrieve_column_comments(table_name, *(cols.map(&:name)))

        cols.each do |col|
          col.comment = comments[col.name.to_sym] if comments.has_key?(col.name.to_sym)
        end

        cols
      end
    end

    module CopyTableWithMigrationComments
      def copy_table(from, to, options = {}) #:nodoc:
        options = options.merge(id: (!columns(from).detect { |c| c.name == 'id' }.nil? && 'id' == primary_key(from).to_s))

        unless options.has_key?(:comment)
          table_comment = retrieve_table_comment(from)

          options = options.merge(comment: table_comment) if table_comment
        end

        create_table(to, options) do |definition|
          @definition = definition

          columns(from).each do |column|
            column_name = options[:rename] ?
                (options[:rename][column.name] ||
                    options[:rename][column.name.to_sym] ||
                    column.name) : column.name

            @definition.column(column_name, column.type,
                               limit: column.limit,
                               default: column.default,
                               precision: column.precision,
                               scale: column.scale,
                               null: column.null,
                               comment: column.comment)
          end

          @definition.primary_key(primary_key(from)) if primary_key(from)

          yield @definition if block_given?
        end

        copy_table_indexes(from, to, options[:rename] || {})
        copy_table_contents(from, to, @definition.columns.map { |column| column.name }, options[:rename] || {})
      end
    end

    def create_table(table_name, options = {})
      td = ActiveRecord::ConnectionAdapters::TableDefinition.new(self)
      td.primary_key(options[:primary_key] || ActiveRecord::Base.get_primary_key(table_name.to_s.singularize)) if options[:id]
      td.comment options[:comment] if options.has_key?(:comment)
      td.base = self

      yield td if block_given?

      drop_table(table_name) if options[:force] && table_exists?(table_name)

      create_sql = "CREATE#{' TEMPORARY' if options[:temporary]} TABLE "

      create_sql << "#{quote_table_name(table_name)}#{td.table_comment} ("

      create_sql << td.columns.map do |column|
        column.to_sql + column.comment.to_s
      end * ', '

      create_sql << ") #{options[:options]}"

      execute create_sql
    end
  end
end
