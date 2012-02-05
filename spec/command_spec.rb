require "spec_helper"
require "stringio"

shared_examples_for "a subclass of Command::Base" do 
  it { should be_a_kind_of(ITunes::Store::Transporter::Command::Base) }

  context "when on Windows" do 
    it "automatically sets NoPause to true"
  end
  
  describe "options" do 
    describe ":print_stderr" do 
      before :each do
        @realerr = $stderr
        $stderr = StringIO.new
        mock_output(:stderr => ["ERR 1"])
        described_class.new(:print_stderr => print?).run(options)
      end

      after(:each) { $stderr = @realerr }

      context "when true" do
        let(:print?) { true }

        it "prints to stderr" do 
          $stderr.string.chomp.should == "ERR 1"
        end
      end

      context "when false" do 
        let(:print?) { false }

        it "does not print to stderr" do 
          $stderr.string.should be_empty
        end
      end
    end

    # TODO: Some DRYing, maybe
    describe ":print_stdout" do 
      before :each do
        @realout = $stdout
        $stdout = StringIO.new
        mock_output(:stdout => ["OUT 1"])
        described_class.new(:print_stdout => print?).run(options)
      end

      after(:each) { $stdout = @realout }

      context "when true" do
        let(:print?) { true }

        it "prints to stdout" do 
          $stdout.string.chomp.should == "OUT 1"
        end
      end

      context "when false" do 
        let(:print?) { false }

        it "does not print to stdout" do 
          $stdout.string.should be_empty
        end
      end
    end
  end

  context "when successful" do
    it "calls #handle_success" do 
      mock_output(:exit => 0)
      subject.should_receive(:handle_success)      
      subject.should_not_receive(:handle_error)      
      subject.run(options)
    end
  end

  context "when not successful" do
    it "calls #handler_error" do 
      mock_output(:exit => 1)
      subject.should_receive(:handle_error)      
      subject.should_not_receive(:handle_success)      
      subject.run(options)
    end

    context "when an error is output to stderr" do
      it "raises an ExecutionError" do 
        mock_output(:exit => 1, :stderr => "stderr.errors")
        lambda { subject.run(options) }.should raise_error(ITunes::Store::Transporter::ExecutionError)
      end
    end
  end
end

shared_examples_for "a transporter mode" do   
  it_should_behave_like "a subclass of Command::Base"

  it { should be_a_kind_of(ITunes::Store::Transporter::Command::Mode) }  

  #it "passes the mode string as an argument"

  it "requires a username" do 
    args = options
    args.delete(:username)
    lambda { subject.run(args) }.should raise_error(ITunes::Store::Transporter::OptionError, /username/)
  end
  
  it "requires a password" do 
    args = options
    args.delete(:password)
    lambda { subject.run(args) }.should raise_error(ITunes::Store::Transporter::OptionError, /password/)
  end
end

shared_examples_for "a command that requires a package argument" do     
  context "when missing" do 
    it "will raise an OptionError" do 
      options = create_options
      lambda { subject.run(options) }.should raise_error(ITunes::Store::Transporter::OptionError, /package/)
    end
  end
  
  # context "when given" do 
  #   before(:all) { @tmpdir = Dir.mktmpdir }
  #   after(:all) { FileUtils.rm_rf(@tmpdir) }

  #   context "as a file" do 
  #     it "raises an OptionError" do 
  #       path = Tempfile.new("").path
  #       options = create_options(:package => path)
  #       lambda { subject.run(options) }.should raise_error(ITunes::Store::Transporter::OptionError, /dir/i)
  #     end
  #   end

  #   context "as a directory that does not end in .itmsp" do 
      
  #   end

  #   context "when given as a directory that does end in .itmsp" do 
      
  #   end


  #   it "must be end in .itmsp" do 
  #     options = create_options(:package => @tmpdir)
  #     lambda { subject.run(options) }.should raise_error(ITunes::Store::Transporter::OptionError, /dir/i)
  #   end  
  # end
end

describe ITunes::Store::Transporter::Command::Providers do
  it_behaves_like "a transporter mode"

  subject { described_class.new({}) }
  let(:options) { create_options }
  its(:mode) { should == "provider" }

  describe "#run" do 
    it "returns the shortname and longname for each provider" do 
      mock_output(:stdout => "providers.two", :stderr => "stderr.info")    
      subject.run(options).should == [ { :longname => "Some Great User", :shortname => "luser" }, 
                                       { :longname => "Skye's Taco Eating Service Inc.", :shortname => "conmuchacebolla" } ]
    end
  end
end

describe ITunes::Store::Transporter::Command::Upload do
  it_behaves_like "a transporter mode"

  subject { described_class.new({}) }  
  let(:options) { create_options(:package => create_package, :transport => "Aspera")  }
  after(:each) { FileUtils.rm_rf(options[:package]) }

  describe "#run" do 
    context "when successful" do 
      it "returns true" do 
        mock_output(:stdout => "stdout.success")    
        subject.run(options).should be_true
      end   
    end
  end
end

describe ITunes::Store::Transporter::Command::Lookup do
  it_behaves_like "a transporter mode"

  subject { described_class.new({}) }
  let(:options) { create_options(:vendor_id => "X") }  
  its(:mode) { should == "lookupMetadata" }

  describe "#run" do 
    context "when successful" do 
      before(:all) do 
        @tmpdir = Dir.mktmpdir
        Dir.stub(:mktmpdir => @tmpdir)

        @package = File.join(@tmpdir, "#{options[:vendor_id]}.itmsp")
        Dir.mkdir(@package)
      end
    
      after(:all) { FileUtils.rm_rf(@tmpdir) }
  
      it "returns the metadata" do     
        metadata = "<x>Metadata</x>"
        File.open(File.join(@package, "metadata.xml"), "w") { |io| io.write(metadata) }      
        
        mock_output
        subject.run(options).should == metadata
      end
  
      it "deletes the temp directory used to output the metadata" do 
        File.exists?(@tmpdir).should be_false
      end
    end
  end
end

describe ITunes::Store::Transporter::Command::Schema do
  it_behaves_like "a transporter mode"

  subject { described_class.new({}) }
  let(:options) { create_options(:type => "strict", :version => "film5") }
  its(:mode) { should == "generateSchema" }

  describe "#run" do 
    context "when successful" do 
      it "returns the requested schema" do     
        mock_output(:stdout => [ "<x>Film Schema</x>" ], :stderr => "stderr.info")
        subject.run(options).should == "<x>Film Schema</x>"
      end
    end
  end
end

describe ITunes::Store::Transporter::Command::Status do
  it_behaves_like "a transporter mode"

  subject { described_class.new({}) }
  let(:options) { create_options(:vendor_id => 123123) }
  its(:mode) { should == "status" }

  describe "#run" do 
    context "when successful" do 
      it "returns the status information for the package" do 
        mock_output(:stdout => "status.vendor_id_123123", :stderr => "stderr.info")
        subject.run(options).should == { 
          :vendor_identifier => "123123",
          :apple_identifier => "123123",
          :itunesconnect_status => "Not ready for sale", 
          :upload_created =>  "2000-01-01 00:00:00", 
          :upload_state => "Uploaded", 
          :upload_state_id => "1", 
          :content_state => "Irie", 
          :content_state_id => "2"
        }
      end
    end
  end
end

describe ITunes::Store::Transporter::Command::Verify do
  it_behaves_like "a transporter mode"
  it_behaves_like "a command that requires a package argument"    

  subject { described_class.new({}) }
  its(:mode) { should == "verify" }
  let(:options) { create_options(:package => create_package) }

  describe "#run" do 
    context "when successful" do  #successful means exit(0)
      context "without any errors" do 
        it "returns true" do 
          mock_output(:stdout => "stdout.success", :stderr => "stderr.info")
          subject.run(options).should be_true
        end
      end
    
      # If no packages were verfied it exits with 0 but emits an error message
      context "with errors" do 
        it "raises an ExecutionError" do 
          mock_output(:exit => 0, :stderr => "stderr.errors");
          lambda { subject.run(options) }.should raise_exception(ITunes::Store::Transporter::ExecutionError)    
        end
      end
    end
  end
end

describe ITunes::Store::Transporter::Command::Version do
  subject { described_class.new({}) }

  def output_version(v)
    ["iTMSTransporter version #{v}"]        
  end
   
  describe "#run" do 
    context "when the version is major" do 
      it "returns the version" do 
        mock_output(:stdout => output_version("1"))
        subject.run.should == "1"
      end
    end

    context "when the version is major.minor" do 
      it "returns the version" do 
        mock_output(:stdout => output_version("1.10"))
        subject.run.should == "1.10"
      end
    end

    context "when the version is major.minor.release" do 
      it "returns the version" do 
        mock_output(:stdout => output_version("1.10.100"))
        subject.run.should == "1.10.100"
      end
    end

    context "when the version is major.minor.release.build format" do 
      it "returns the version" do 
        mock_output(:stdout => output_version("1.10.100.1234"))
        subject.run.should == "1.10.100.1234"
      end
    end

    context "when the version it's somthing else" do 
      it "returns 'Unknown'" do 
        mock_output(:stdout => ["bad version here"])
        subject.run.should == "Unknown"
      end
    end
  end   
end
