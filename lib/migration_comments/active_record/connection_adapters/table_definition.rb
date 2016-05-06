module MigrationComments::ActiveRecord::ConnectionAdapters
  module TableDefinition
    attr_accessor :table_comment

    def self.included(base)
      base.class_eval do
        attr_accessor :base
      end

      base.send :prepend, ColumnWithMigrationComments
    end

    module ColumnWithMigrationComments
      def column(name, type, options = {})
        super(name, type, options)

        if options.has_key?(:comment)
          col = self[name]

          col.comment = CommentDefinition.new(base, nil, name, options[:comment])
        end

        self
      end
    end

    def comment(text)
      @table_comment = CommentDefinition.new(base, nil, nil, text)

      self
    end

    def collect_comments(table_name)
      comments = []
      comments << @table_comment << columns.map(&:comment)

      comments.flatten!.compact!

      comments.each do |comment|
        comment.table = table_name
        comment.adapter = base
      end
    end
  end
end
