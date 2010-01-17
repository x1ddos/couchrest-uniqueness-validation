$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'couchrest'
require 'couchrest/mixins/validation'
require 'couchrest-uniqueness-validation'
require 'spec'
require 'spec/autorun'

unless defined?(SPEC_COUCH)
  COUCH_URL = "http://127.0.0.1:5984"
  COUCH_NAME = 'couchrest-test'

  SPEC_COUCH = CouchRest.database!("#{COUCH_URL}/#{COUCH_NAME}")
end

Spec::Runner.configure do |config|
  config.before(:all) {
    SPEC_COUCH.recreate! rescue nil
  }
  
  config.after(:all) do
    SPEC_COUCH.delete! rescue nil
  end
end
