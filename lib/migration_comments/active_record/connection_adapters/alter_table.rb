module MigrationComments::ActiveRecord::ConnectionAdapters
  module AlterTable
    def self.included(base)
      base.send :prepend, AddColumnWithMigrationComments
    end
  end

  module AddColumnWithMigrationComments
    def add_column(name, type, options)
      super(name, type, options)

      if options.keys.include?(:comment)
        column = @adds.last
        column.comment = CommentDefinition.new(nil, @td, name, options[:comment])
      end
    end
  end
end
