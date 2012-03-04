require "spec_helper"
require "stringio"

shared_examples_for "a transporter option" do |option, expected|
  it "creates the correct command line argument" do 
    ITunes::Store::Transporter::Shell.any_instance.stub(:exec) { |*arg| arg.first.should include(*expected); 0 }
    subject.run(options.merge(option))
  end
end

shared_examples_for "a required option" do |option|
  it "must have a value" do 
    ["", nil].each do |value|
      lambda { subject.run(options.merge(option => value)) }.should raise_exception(ITunes::Store::Transporter::OptionError, /#{option}/) 
    end
  end
end

shared_examples_for "a command that accepts a shortname argument" do     
  context "when the shortname's invalid" do 
    it "raises an OptionError" do 
      lambda { subject.run(options.merge(:shortname => "+")) }.should raise_exception(ITunes::Store::Transporter::OptionError, /shortname/)       
    end
  end

  context "when the shortname's valid" do 
    it "does not raise an exception" do 
      mock_output
      lambda { subject.run(options.merge(:shortname => "Too $hort")) }.should_not raise_exception
    end
  end
end

shared_examples_for "a subclass of Command::Base" do 
  it { should be_a_kind_of(ITunes::Store::Transporter::Command::Base) }

  context "when on Windows" do 
    it "automatically sets NoPause to true" do 
      ENV["PROGRAMFILES"] = "C:\\"
      shell = ITunes::Store::Transporter::Shell
      shell.any_instance.stub(:exec) { |*arg| arg.first.should include("-WONoPause", "true") }
      shell.stub(:windows? => true)
      mock_output
      subject.run(options)
    end
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
  it_should_behave_like "a required option", :package

  context "when a directory" do   
    before(:all) do
      @tmpdir = Dir.mktmpdir 
      @pkgdir = File.join(@tmpdir, "package.itmsp")
      Dir.mkdir(@pkgdir)
    end
    
    after(:all) { FileUtils.rm_rf(@tmpdir) }
    
    it "must end in .itmsp" do 
      options = create_options(:package => @tmpdir)
      lambda { subject.run(options) }.should raise_error(ITunes::Store::Transporter::OptionError, /must match/i)

      mock_output(:exit => 0)
      options = create_options(:package => @pkgdir)
      lambda { subject.run(options) }.should_not raise_error
    end    
    
    it "must exist" do       
      options = create_options(:package => File.join(@tmpdir, "badpkg.itmsp"))
      lambda { subject.run(options) }.should raise_error(ITunes::Store::Transporter::OptionError, /does not exist/i)
    end  
  end
  
  context "when a file" do 
    it "raises an OptionError" do 
      path = Tempfile.new("").path
      options = create_options(:package => path)
      # TODO: Optout's error message will probably be changed to something more descriptive, change this when that happens
      lambda { subject.run(options) }.should raise_error(ITunes::Store::Transporter::OptionError, /dir/i)
    end
  end
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
  it_behaves_like "a command that requires a package argument"
  it_behaves_like "a command that accepts a shortname argument"

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

  describe "options" do 
    describe ":rate" do 
      it "must be an integer" do 
        lambda { subject.run(options.merge(:rate => "123")) }.should raise_exception(ITunes::Store::Transporter::OptionError, /rate/)
      end
      
      it_should_behave_like "a transporter option", {:rate => 123}, "-k", "123"
    end

    describe ":transport" do 
      %w|Aspera Signiant DAV|.each do |name|
        context "with #{name}" do 
          it_should_behave_like "a transporter option", {:transport => name}, "-t",  name
        end
      end

      it "is case sensitive" do 
        lambda { subject.run(options.merge(:transport => "aspera")) }.should raise_exception(ITunes::Store::Transporter::OptionError)
      end
      
      it "raises an OptionError if the transport is not supported" do 
        lambda { subject.run(options.merge(:transport => "ftp")) }.should raise_exception(ITunes::Store::Transporter::OptionError)
      end     
    end

    describe ":delete_on_success" do 
      it "raises an OptionError if not boolean" do 
        lambda { subject.run(options.merge(:delete_on_success => 1)) }.should raise_exception(ITunes::Store::Transporter::OptionError)

      end

      context "when true" do 
        it_should_behave_like "a transporter option", {:delete_on_success => true}, "-delete"
      end

      # This should not include, probably better to say:
      # subject.run.should include_option
      # subject.run.should_not include_option
      #context "when false" do 
      #  it_should_behave_like "a transporter option", {:delete_on_success => false}, "-delete"
      #end
    end

    describe ":log_history" do
      it_should_behave_like "a transporter option", {:log_history => "."}, "-loghistory", "."
    end

    describe ":delete" do
      it_should_behave_like "a transporter option", {:delete => true}, "-delete"
    end

    describe ":on_success" do 
      context "when the directory does not exist" do 
        it "raises an OptionError" do 
          lambda { subject.run(options.merge(:on_success => "__baaaaahd_directory__")) }.should raise_exception(ITunes::Store::Transporter::OptionError)
        end
      end
      
      it_should_behave_like "a transporter option", {:on_success => "."}, "-success", "."
    end

    describe ":on_failure" do
      it_should_behave_like "a transporter option", {:on_failure => "."}, "-failure",  "."
    end
  end
end

describe ITunes::Store::Transporter::Command::Lookup do
  it_behaves_like "a transporter mode"
  it_behaves_like "a command that accepts a shortname argument" 

  subject { described_class.new({}) }
  let(:options) { create_options(:vendor_id => "X") }  
  its(:mode) { should == "lookupMetadata" }

  describe "#run" do 
    context "when successful" do 

      # iTMSTransporter creates a directory containing the metadata
      before(:all) do 
        @tmpdir = Dir.mktmpdir
        Dir.stub(:mktmpdir => @tmpdir)

        @package = File.join(@tmpdir, "#{options[:vendor_id]}.itmsp")
        Dir.mkdir(@package)

        @metadata = "<x>Metadata</x>"
        File.open(File.join(@package, "metadata.xml"), "w") { |io| io.write(@metadata) }      
        
        mock_output
      end
    
      after(:all) { FileUtils.rm_rf(@tmpdir) }
  
      it "returns the metadata" do     
        subject.run(options).should == @metadata
      end
  
      it "deletes the temp directory used to output the metadata" do 
        File.exists?(@tmpdir).should be_false
      end
    end
  end

  describe "options" do 
    describe ":vendor_id" do 
    end
  end
end

describe ITunes::Store::Transporter::Command::Schema do
  it_behaves_like "a transporter mode"
  it_behaves_like "a command that accepts a shortname argument"

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

  # destination
  describe "options" do 
    describe ":version" do 
      it_should_behave_like "a transporter option", {:version => "versionX"}, "-schema",  "versionX"
    end

    # Like Upload's :trasport, case sen., limited to a set
    describe ":type" do 
      %w|transitional strict|.each do |type|
        context "with #{type}" do 
          it_should_behave_like "a transporter option", {:type => type}, "-schemaType", type
        end
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
  
  #describe "options" 
  #:vendor_id
end

describe ITunes::Store::Transporter::Command::Verify do
  it_behaves_like "a transporter mode"
  it_behaves_like "a command that requires a package argument"    
  it_behaves_like "a command that accepts a shortname argument"

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

  describe "options" do 
    # should not include 
    #describe ":verify_assets" do 
    #it_should_behave_like "a transporter option", {:verify_assets => false}, "-disableAssetVerification"
    #end
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


