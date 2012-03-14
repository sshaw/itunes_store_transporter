require "itunes/store/transporter"

describe ITunes::Store::Transporter do
  describe "#new" do 
    context "when the options are not a Hash or nil" do 
      it "raises an ArgumentError" do 
        lambda { described_class.new(123) }.should raise_exception(ArgumentError, /must be/)
      end
    end
  end

  describe "#providers" do 
    it "inherrits the defaults" do
      config = { 
        :path => "/",
        :print_stderr => true,
        :print_stdout => true       
      }

      defaults = create_options # { :username => "sh" }

      cmd = ITunes::Store::Transporter::Command::Providers.any_instance
      cmd.should_receive(:new).with(config, defaults).should_receive(:run)
      described_class.new(config.merge(defaults)).providers
    end

    # it "executes the command" do 
    #   ITunes::Store::Transporter::Command::Providers.any_instance.should_receive(:run)
    #   subject.providers
    # end
  end

  describe "#upload" do 
    it "executes the command" do 
      ITunes::Store::Transporter::Command::Upload.any_instance.should_receive(:run).with(:package => "package.itmsp")
      subject.upload("package.itmsp")
    end
  end

  describe "#verify" do 
    it "executes the command" do 
      ITunes::Store::Transporter::Command::Verify.any_instance.should_receive(:run).with(:package => "package.itmsp")
      subject.verify("package.itmsp")
    end
  end
end
