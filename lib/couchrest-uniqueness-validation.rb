# Based on original validators in CouchRest::Validation
module CouchRest
  module Validation
    
    class UniquenessValidator < GenericValidator
      def initialize(field_name, options = {})
        super
        @field_name, @options = field_name, options
        @options[:view] ||= "by_#{@field_name}".to_sym
      end
      
      def call(target)
        return true if unique?(target)
        
        error_message = @options[:message] || ValidationErrors.default_error_message(:taken, field_name)
        add_error(target, error_message, field_name)        
        false
      end
      
      protected
      
      def unique?(target)
        value = target.validation_property_value(@field_name)
        existing_docs = target.class.view(@options[:view], :key => value, :limit => 1, :include_docs => false)
        
        # normal case when target.new_document? == true and
        # no other document exists
        return true if existing_docs.empty? 
        
        # we got here because either another document does exist or
        # we're validating an existing document
        existing_docs.reject! { |d| d['id'] == target.id } unless target.new_document?
        existing_docs.empty?
      end
    end # class UniquenessValidator
    
    module ValidatesUniqueness
      
      ##
      # Validates that the specified attribute is unique across documents with the same 
      # couchrest-type using a view.
      #
      # @note
      #   You have to define a design doc view.
      # @see http://rdoc.info/rdoc/couchrest/couchrest/blob/1b34fe4b60694683e98866a51c2109c1885f7e42/CouchRest/Mixins/Views/ClassMethods.html#view_by-instance_method for more details about views.
      #
      # @example [Usage]
      # 
      #   class User
      #   
      #     property :nickname
      #     property :login
      #
      #     view_by :nickname
      #
      #     # assumes that a view :by_nickname is present
      #     validates_uniqueness_of :nickname
      #
      #     # uses a different from default view 
      #     validates_uniqueness_of :login, :view => 'my_custom_view'
      #
      #     # a call to valid? will return false unless no other document exists with
      #     # the same couchrest-type, nickname and login
      #   end
      def validates_uniqueness_of(*fields)
        opts = opts_from_validator_args(fields)
        add_validator_to_context(opts, fields, CouchRest::Validation::UniquenessValidator)
      end
      
    end # module ValidatesUniqueness
    
    module ClassMethods
      include CouchRest::Validation::ValidatesUniqueness
    end
  end # module Validation
end # module CouchRest
