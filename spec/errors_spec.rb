require "spec_helper"

describe ITunes::Store::Transporter::TransporterMessage do
  subject { ITunes::Store::Transporter::TransporterMessage.new("some message", 1) }
  its(:code) { should == 1 }
  its(:message) { should == "some message" }

  describe "#to_s" do     
    it "includes the code and message" do 
      subject.to_s.should == "some message (1)"
    end    
  end

  describe "error predicate methods" do 
  end
end

describe ITunes::Store::Transporter::ExecutionError do 
#  its(:exitstatus) {}
end
