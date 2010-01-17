require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CouchRest::Validation::ValidatesUniqueness do
  
  class SomeDoc < CouchRest::ExtendedDocument
    include CouchRest::Validation
    use_database SPEC_COUCH
  end
  
  it "should provide validates_uniqueness_of method" do
    SomeDoc.should respond_to :validates_uniqueness_of
  end
end

describe CouchRest::Validation::UniquenessValidator do
  
  class SomeUniqueDoc < CouchRest::ExtendedDocument
    include CouchRest::Validation
    use_database SPEC_COUCH
    
    property :unique_prop    
    validates_uniqueness_of :unique_prop
  end
  
  before(:each) do
    @some_doc = SomeUniqueDoc.new :unique_prop => 'some property value'
    SomeUniqueDoc.stub(:view).and_return({'rows' => []})
  end
  
  it "should use a corresponding default view for uniqueness test" do
    SomeUniqueDoc.should_receive(:view).
      with(:by_unique_prop, hash_including(:key => @some_doc.unique_prop, :limit => 1, :include_docs => false))
    @some_doc.valid?
  end
  
  it "should pass validation if no other document exist with the same property value" do
    @some_doc.should be_valid
  end
  
  it "should not pass validation if another document exists already" do
    SomeUniqueDoc.should_receive(:view).and_return({'rows' => [{'id' => 123}]})
    @some_doc.should_not be_valid
    @some_doc.errors.should have_key :unique_prop
  end
  
  it "should pass validation for an existing document (should remove itself from the list)" do
    SomeUniqueDoc.should_receive(:view).and_return({'rows' => [{'id' => 123}]})
    @some_doc.stub(:new_document?).and_return(false)
    @some_doc.stub(:id).and_return(123)
    @some_doc.should be_valid
  end
  
  describe "using custom view" do
    
    class SomeOtherUniqueDoc < CouchRest::ExtendedDocument
      include CouchRest::Validation
      use_database SPEC_COUCH
      
      property :another_prop
      validates_uniqueness_of :another_prop, :view => 'my_custom_view'
    end
    
    before(:each) do
      @some_doc = SomeOtherUniqueDoc.new :another_prop => 'some property value'
      SomeOtherUniqueDoc.stub(:view).and_return({'rows' => []})
    end
    
    it "should work" do
      SomeOtherUniqueDoc.should_receive(:view).
        with(:my_custom_view, hash_including(:key => @some_doc.another_prop, :limit => 1, :include_docs => false))
      @some_doc.valid?
    end
  end
end