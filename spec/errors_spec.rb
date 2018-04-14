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
    method_codes = {
      :bad_data? => [3000, 3999],
      :invalid_data? => [4000, 4999],
      :missing_data? => [5000, 5999],
      :unsupported_feature? => [6000, 6999],
      :schema_error? => [8000, 8999],
      :asset_error? => [9000, 9999]
    }

    method_codes.each do |method, codes|
      [codes.first, codes.last].each do |code|

        context "code #{code}" do
          subject { described_class.new("", code) }
          its(method) { should be true }
          its(:validation_error?) { should be true }

          (method_codes.keys - [method]).each do |other|
            its(other) { should be false }
          end
        end
      end
    end
  end
end

describe ITunes::Store::Transporter::ExecutionError do
  subject { described_class.new(messages, 1) }
  let(:messages) { 2.times.inject([]) { |err, i| err << ITunes::Store::Transporter::TransporterMessage.new("message #{i}", i) } }
  its(:exitstatus) { should == 1 }
  its(:errors) { should == messages }

  describe "#to_s" do
    it "includes each messages and its code" do
      subject.to_s.should == "message 0 (0), message 1 (1)"
    end
  end
end
