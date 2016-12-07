require "spec_helper"
require "itunes/store/transporter"

shared_examples_for "a transporter method" do
  it "uses the default options" do
    defaults = create_options
    config = {
      :path => "/",
      :print_stderr => true,
      :print_stdout => true
    }

    s = double(command)
    allow(s).to receive(:run)

    klass = ITunes::Store::Transporter::Command.const_get(command)
    klass.should_receive(:new).with(config, defaults).and_return(s)

    described_class.new(config.merge(defaults)).send(method, options)
  end
end

shared_examples_for "a transporter method without a package argument" do
  it_behaves_like "a transporter method"

  it "executes the underlying command" do
    ITunes::Store::Transporter::Command.const_get(command).any_instance.should_receive(:run).with(options)
    subject.send(method, options)
  end
end

shared_examples_for "a transporter method with a package argument" do
  it_behaves_like "a transporter method"

  it "executes the underlying command" do
    ITunes::Store::Transporter::Command.const_get(command).any_instance.should_receive(:run).with(:package => "package.itmsp")
    subject.send(method, "package.itmsp")
  end
end


describe ITunes::Store::Transporter::ITMSTransporter do
  let(:options) { {} }

  describe "#new" do
    context "when the options are not a Hash or nil" do
      it "raises an ArgumentError" do
	lambda { described_class.new(123) }.should raise_exception(ArgumentError, /must be/)
      end
    end
  end

  describe "#lookup" do
    let(:method) { :lookup }
    let(:command) { "Lookup" }

    it_behaves_like "a transporter method without a package argument"

    it "executes the underlying command" do
      ITunes::Store::Transporter::Command::Lookup.any_instance.should_receive(:run)
      subject.lookup
    end
  end

  describe "#providers" do
    let(:method) { :providers }
    let(:command) { "Providers" }

    it_behaves_like "a transporter method without a package argument"
  end

  describe "#schema" do
    let(:method) { :schema }
    let(:command) { "Schema" }

    it_behaves_like "a transporter method without a package argument"
  end

  describe "#status" do
    let(:method) { :status }
    let(:command) { "Status" }

    it_behaves_like "a transporter method without a package argument"

    context "when given :history => true" do
      it "runs the status all command" do
        ITunes::Store::Transporter::Command::StatusAll.any_instance.should_receive(:run)
        subject.status(:history => true)
      end
    end

    context "when given :history => false" do
      it "runs the status command" do
        ITunes::Store::Transporter::Command::Status.any_instance.should_receive(:run)
        subject.status(:history => false)
      end
    end
  end

  describe "#upload" do
    let(:method) { :upload }
    let(:command) { "Upload" }

    it_behaves_like "a transporter method with a package argument"
  end

  describe "#verify" do
    let(:method) { :verify }
    let(:command) { "Verify" }

    it_behaves_like "a transporter method with a package argument"
  end

  describe "#version" do
    let(:method) { :version }
    let(:command) { "Version" }

    it_behaves_like "a transporter method without a package argument"
  end
end
