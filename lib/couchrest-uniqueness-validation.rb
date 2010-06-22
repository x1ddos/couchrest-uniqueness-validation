# Based on original validators in CouchRest::Validation
require 'couchrest/mixins/validation'

module CouchRest
  module Validation
    
    class UniquenessValidator < GenericValidator
      def initialize(field_name, options = {})
        super
        @field_name, @options = field_name, options
        @options[:view] ||= "by_#{@field_name}"
        @options[:downcase] ||= false
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
        value.downcase! if @options[:downcase] && !value.blank?
        existing_docs = target.class.view(@options[:view].to_sym, :key => value, :limit => 1, :include_docs => false)['rows']
        
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
      # == Example
      #
      #   require 'rubygems'
      #   require 'couchrest'
      #   require 'couchrest-uniqueness-validation' 
      #
      #   class User < CouchRest::ExtendedDocument
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
      #     validates_uniqueness_of :login, :view => 'by_my_custom_view'
      #
      #     # or, you can do a case insensitive uniqueness validation
      #     validates_uniqueness_of :login, :view => 'by_case_insensitive_login_view', :downcase => true
      #     # view_by :case_insensitive_login_view, :map => "function(doc) {if (doc.login) {emit(doc.title.toLowerCase(), 1);}}"
      #
      #     # a call to valid? will return false unless no other document exists with
      #     # the same couchrest-type, nickname and login
      #   end
      #
      # Note: at least two views should exist in the User design doc for this example to work - 
      # :by_nickname and :my_custom_view.
      # 
      # See {CouchRest Views docs}[http://rdoc.info/rdoc/couchrest/couchrest/blob/1b34fe4b60694683e98866a51c2109c1885f7e42/CouchRest/Mixins/Views/ClassMethods.html#view_by-instance_method] 
      # for more info on views
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
