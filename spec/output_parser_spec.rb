require "spec_helper"

describe ITunes::Store::Transporter::OutputParser do
  describe "parsing errors" do     
    it "should parse erorrs without an error code" do 
      lines = Fixture.for("errors_and_warnings.no_error_number")
      parser = described_class.new(lines)
      parser.warnings.should be_empty
      errors = parser.errors
      errors.should have(2).items
      errors.first.code.should be_nil
      errors.first.message.should == "An error occurred while doing fun stuff"
      errors.last.code.should be_nil
      errors.last.message.should == "An exception has occurred: network timeout"
    end

    it "should parse erorrs with an error code"     
  end

  describe "parsing warnings" do 
  end
end
