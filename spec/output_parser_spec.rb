require "spec_helper"

describe ITunes::Store::Transporter::OutputParser do
  describe "parsing errors" do
    # TODO: test various error message/code formats handled by the parser

    context "without an error code" do
      before(:all) { @parser = described_class.new(fixture("errors_and_warnings.no_error_number")) }

      subject { @parser }
      its(:warnings) { should be_empty }
      its(:errors) { should have(2).items }

      describe "the first error" do
        subject { @parser.errors.first }
        its(:code) { should be_nil }
        its(:message) { should == "An error occurred while doing fun stuff" }
      end

      describe "the second error" do
        subject { @parser.errors.last }
        its(:code) { should be_nil }
        its(:message) { should == "An exception has occurred: network timeout" }
      end
    end

    context "with errors from main and from a class" do
      before(:all) { @parser = described_class.new(fixture("errors_and_warnings.error_from_main_and_class")) }
      subject { @parser }

      it "only parses the error from main" do
        expect(@parser.errors.size).to eq 1
        expect(@parser.errors.first.message).to eq "Another error has occurred"
      end
    end

    context "with an error code" do
      before(:all) { @parser = described_class.new(fixture("errors_and_warnings.with_error_number")) }

      subject { @parser }
      its(:warnings) { should be_empty }
      its(:errors) { should have(2).items }


      describe "the first error" do
        subject { @parser.errors.first }
        its(:code) { should == 4000 }
        its(:message) { should == "This is error 4000" }
      end

      describe "the second error" do
        subject { @parser.errors.last }
        its(:code) { should == 5000 }
        its(:message) { should == "This is error 5000" }
      end
    end

    context "with duplicate messages" do
      before(:all) { @parser = described_class.new(fixture("errors_and_warnings.duplicate_errors")) }

      it "does not include duplicates" do
        errors = @parser.errors.map { |e| e.message }
        errors.should == ["Error 1", "Error 2", "Error 3"]
      end
    end
  end

  describe "parsing warnings" do
    before(:all) { @parser = described_class.new(fixture("errors_and_warnings.single_warning")) }

    subject { @parser }
    its(:errors) { should be_empty }
    its(:warnings) { should have(1).item }

    describe "the warning" do
      subject { @parser.warnings.first }
      its(:code) { should == 4010 }
      its(:message) { should == "You've been warned!" }
    end
  end
end
