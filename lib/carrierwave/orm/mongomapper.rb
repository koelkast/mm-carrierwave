# encoding: utf-8

require 'mongo_mapper'
require 'carrierwave/validations/active_model'

module CarrierWave
  module MongoMapper
    include CarrierWave::Mount
    ##
    # See +CarrierWave::Mount#mount_uploader+ for documentation
    #
    def mount_uploader(column, uploader, options={}, &block)
      key options[:mount_on] || column

      super

      alias_method :read_uploader, :read_attribute
      alias_method :write_uploader, :write_attribute
      public :read_uploader
      public :write_uploader

      include CarrierWave::Validations::ActiveModel

      validates_integrity_of  column if uploader_option(column.to_sym, :validate_integrity)
      validates_processing_of column if uploader_option(column.to_sym, :validate_processing)

      after_save "store_#{column}!".to_sym
      before_save "write_#{column}_identifier".to_sym
      after_destroy "remove_#{column}!".to_sym
      before_update "store_previous_model_for_#{column}".to_sym
      after_save "remove_previously_stored_#{column}".to_sym

      class_eval <<-RUBY, __FILE__, __LINE__+1
        def #{column}=(new_file)
          column = _mounter(:#{column}).serialization_column
          send(:"\#{column}_will_change!")
          super
        end

        def find_previous_model_for_#{column}
          if self.kind_of?(::MongoMapper::EmbeddedDocument)
            haystack = [self._parent_document, self]
            while haystack.first.kind_of?(::MongoMapper::EmbeddedDocument)
              haystack.unshift(haystack.first._parent_document)
            end
            reloaded_parent = haystack.first.reload
            found = haystack.inject(reloaded_parent) do |parent, ancestor|
              if ancestor == parent
                parent
              else  
                collection = ancestor.class.to_s.tableize.gsub(/\\\//, '.')
                parent.send(collection).to_a.find { |doc| doc.id == ancestor.id }
              end
            end
            found
          else
            self.class.find(to_key.first)
          end
        end
      RUBY
    end
  end
end

MongoMapper::Plugins::Rails::ClassMethods.send(:include, CarrierWave::MongoMapper)