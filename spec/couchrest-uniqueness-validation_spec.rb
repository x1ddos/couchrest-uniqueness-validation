require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CouchRest::Validation::ValidatesUniqueness do
  
  class SomeExtDoc < CouchRest::ExtendedDocument
    include CouchRest::Validation
    use_database SPEC_COUCH
  end
  
  it "should provide validates_uniqueness_of method" do
    SomeExtDoc.should respond_to :validates_uniqueness_of
  end
end
