require "spec_helper"
require "stringio"

shared_examples_for "a transporter option" do |option, expected|
  it "creates the correct command line argument" do
    expect_shell_args(*expected)
    subject.run(options.merge(option))
  end
end

shared_examples_for "a vendor_id option" do
  it_should_behave_like "a transporter option", { :vendor_id => "vID" }, "-vendor_id", "vID"
end

shared_examples_for "a transporter option that expects a directory" do |option, expected|
  context "when the directory exists" do
    it_should_behave_like "a transporter option", {option => "."}, expected, "."
  end

  context "when the directory does not exist" do
    it "raises an OptionError" do
      expect { subject.run(options.merge(option => "__baaaaahd_directory__")) }.to raise_exception(ITunes::Store::Transporter::OptionError, /does not exist/)
    end
  end
end

shared_examples_for "a boolean transporter option" do |option, expected|
  context "when true" do
    it "creates the command line argument" do
      expect_shell_args(*expected)
      subject.run(options.merge(option => true))
    end
  end

  context "when false" do
    it "does not create the command line argument" do
      allow_any_instance_of(ITunes::Store::Transporter::Shell).to receive(:exec) { |shell, arg| expect(arg).not_to include(*expected); 0 }
      subject.run(options.merge(option => false))
    end
  end

  context "when not boolean" do
    it "raises an OptionError" do
      expect { subject.run(options.merge(option => "sshaw")) }.to raise_exception(ITunes::Store::Transporter::OptionError, /does not accept/)
    end
  end
end

shared_examples_for "a required option" do |option|
  it "must have a value" do
    ["", nil].each do |value|
      expect { subject.run(options.merge(option => value)) }.to raise_exception(ITunes::Store::Transporter::OptionError, /#{option}/)
    end
  end
end

shared_examples_for "a command that accepts an itc_provider argument" do
  it_should_behave_like "a transporter option", { :itc_provider => "sshaw" }, "-itc_provider", "sshaw"
end

shared_examples_for "a command that accepts a shortname argument" do
  it_should_behave_like "a transporter option", { :shortname => "sshaw" }, "-s", "sshaw"

  context "when the shortname's invalid" do
    it "raises an OptionError" do
      expect { subject.run(options.merge(:shortname => "+")) }.to raise_exception(ITunes::Store::Transporter::OptionError, /shortname/)
    end
  end

  context "when the shortname's valid" do
    it "does not raise an exception" do
      mock_output
      expect { subject.run(options.merge(:shortname => "Too $hort")) }.to_not raise_exception
    end
  end
end

shared_examples_for "a subclass of Command::Base" do
  it { is_expected.to be_a_kind_of(ITunes::Store::Transporter::Command::Base) }

  context "when on Windows" do
    it "automatically sets NoPause to true" do
      ENV["PROGRAMFILES"] = "C:\\"
      shell = ITunes::Store::Transporter::Shell
      expect_shell_args("-WONoPause", "true")
      shell.stub(:windows? => true)
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
          expect($stderr.string).to be_empty
        end
      end
    end

    # TODO: Needs some DRYing
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
          expect($stdout.string).to be_empty
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
        lambda { subject.run(options) }.should raise_error { |e|
          expect(e).to be_a(ITunes::Store::Transporter::ExecutionError)

          expect(e.exitstatus).to eq 1
          expect(e.errors.size).to eq 2

          # just check one
          expect(e.errors[0]).to be_a(ITunes::Store::Transporter::TransporterMessage)
          expect(e.errors[0].code).to eq 9000
          expect(e.errors[0].message).to match("Your audio of screwed up!")
          expect(e.errors[1].code).to eq 4009
          expect(e.errors[1].message).to match("Chapter timecode is just plain wrong")
        }
      end
    end
  end
end

shared_examples_for "a transporter mode" do
  it_should_behave_like "a subclass of Command::Base"
  it { is_expected.to be_a_kind_of(ITunes::Store::Transporter::Command::Mode) }

  it "requires a username" do
    args = options
    args.delete(:username)
    expect { subject.run(args) }.to raise_error(ITunes::Store::Transporter::OptionError, /username/)
  end

  it "requires a password" do
    args = options
    args.delete(:password)
    expect { subject.run(args) }.to raise_error(ITunes::Store::Transporter::OptionError, /password/)
  end
end

shared_examples_for "a command that requires a package argument" do
  # TODO: it_should_behave_like "a transporter option", {:package => "xxx"}, "f", "xxx"
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
      expect { subject.run(options) }.to raise_error(ITunes::Store::Transporter::OptionError, /must match/i)

      mock_output(:exit => 0)
      options = create_options(:package => @pkgdir)
      expect { subject.run(options) }.not_to raise_error
    end

    it "must exist" do
      options = create_options(:package => File.join(@tmpdir, "badpkg.itmsp"))
      expect { subject.run(options) }.to raise_error(ITunes::Store::Transporter::OptionError, /does not exist/i)
    end

    context "when it does not end in .itmsp" do
      before do
        @realerr = $stderr
        $stderr = StringIO.new
      end

      after { $stderr = @realerr }

      it "prints a deprecation warning to stderr" do
        options = create_options(:package => @tmpdir)
        subject.run(options) rescue nil
        expect($stderr.string).to match(/^WARNING:/)
      end

      context "and :batch is true" do
        before do
          mock_output
          @options = create_options(:package => @tmpdir, :batch => true)
        end

        it "does not raise an exception" do
          expect { subject.run(@options) }.to_not raise_error
        end

        it "does not print a deprecation warning to stderr" do
          options = create_options(:package => @tmpdir)
          subject.run(@options)
          expect($stderr.string).not_to match(/^WARNING:/)
        end
      end
    end
  end

  context "when a file" do
    it "raises an OptionError" do
      path = Tempfile.new("").path
      options = create_options(:package => path)
      # TODO: Optout's error message will probably be changed to something more descriptive, change this when that happens
      expect { subject.run(options) }.to raise_error(ITunes::Store::Transporter::OptionError, /dir/i)
    end
  end
end

describe ITunes::Store::Transporter::Command::Providers do
  it_behaves_like "a transporter mode"

  subject { described_class.new({}) }
  let(:options) { create_options }

  it "uses Transporter's provider mode" do
    expect_shell_args("-m", "provider")
    subject.run(options)
  end

  describe "#run" do
    it "returns the shortname and longname for each provider" do
      mock_output(:stdout => "providers.two", :stderr => "stderr.info")
      expect(subject.run(options)).to eq [ { :longname => "Some Great User", :shortname => "luser" },
                                           { :longname => "Skye's Taco Eating Service Inc.", :shortname => "conmuchacebolla" } ]
    end
  end
end

describe ITunes::Store::Transporter::Command::Upload do
  it_behaves_like "a transporter mode"
  it_behaves_like "a command that requires a package argument"
  it_behaves_like "a command that accepts a shortname argument"
  it_behaves_like "a command that accepts an itc_provider argument"

  subject { described_class.new({}) }
  let(:options) { create_options(:package => create_package, :transport => "Aspera")  }
  after(:each) { FileUtils.rm_rf(options[:package]) }

  describe "#run" do
    context "when successful" do
      it "returns true" do
        mock_output(:stdout => "stdout.success")
        expect(subject.run(options)).to be true
      end
    end
  end

  describe "options" do
    describe ":rate" do
      it "must be an integer" do
        expect { subject.run(options.merge(:rate => "123")) }.to raise_exception(ITunes::Store::Transporter::OptionError, /rate/)
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
        expect { subject.run(options.merge(:transport => "aspera")) }.to raise_exception(ITunes::Store::Transporter::OptionError)
      end

      it "raises an OptionError if the transport is not supported" do
        expect { subject.run(options.merge(:transport => "ftp")) }.to raise_exception(ITunes::Store::Transporter::OptionError)
      end
    end

    describe ":delete" do
      it_should_behave_like "a boolean transporter option", :delete, "-delete"
    end

    describe ":log_history" do
      it_should_behave_like "a transporter option that expects a directory", :log_history, "-loghistory"
    end

    describe ":success" do
      it_should_behave_like "a transporter option that expects a directory", :success, "-success"
    end

    describe ":failure" do
      it_should_behave_like "a transporter option that expects a directory", :failure, "-failure"
    end
  end
end

describe ITunes::Store::Transporter::Command::Lookup do
  it_behaves_like "a transporter mode"
  it_behaves_like "a command that accepts a shortname argument"
  it_behaves_like "a command that accepts an itc_provider argument"

  subject { described_class.new({}) }

  let(:options) { create_options(:vendor_id => "X") }

  # Fake the directory iTMSTransporter creates for the metadata
  before(:each) do
    @tmpdir = Dir.mktmpdir
    Dir.stub(:mktmpdir => @tmpdir)

    id = options[:vendor_id] || options[:apple_id]
    @package = File.join(@tmpdir, "#{id}.itmsp")
    Dir.mkdir(@package)

    @metadata = "<x>Metadata</x>"
    File.open(File.join(@package, "metadata.xml"), "w") { |io| io.write(@metadata) }
  end

  after(:each) { FileUtils.rm_rf(@tmpdir) }

  it "uses Transporter's lookupMetadata mode" do
    expect_shell_args("-m", "lookupMetadata")
    subject.run(options)
  end

  describe "#run" do
    before { mock_output }

    context "when successful" do
      it "returns the metadata and deletes the temp directory used to output the metadata" do
        expect(subject.run(options)).to eq @metadata
        expect(File.exist?(@tmpdir)).to be false
      end

      context "when the metadata file was not created" do
        before { FileUtils.rm_rf(@tmpdir) }

        it "raises a TransporterError" do
          expect { subject.run(options) }.to raise_exception(ITunes::Store::Transporter::TransporterError, /no metadata file/i)
        end
      end
    end
  end

  # One of these two should be requied, but they should be mutually exclusive
  describe "options" do
    describe ":vendor_id" do
      let(:options) { create_options({:vendor_id => "vID"}) }
      it_should_behave_like "a vendor_id option"
    end

    describe ":apple_id" do
      let(:options) { create_options({:apple_id => "aID"}) }
      it_should_behave_like "a transporter option", { :apple_id => "aID" }, "-apple_id", "aID"
     end
  end
end

describe ITunes::Store::Transporter::Command::Schema do
  it_behaves_like "a transporter mode"
  it_behaves_like "a command that accepts a shortname argument"
  it_behaves_like "a command that accepts an itc_provider argument"

  subject { described_class.new({}) }
  let(:options) { create_options(:type => "strict", :version => "film5") }

  it "uses Transporter's generateSchema mode" do
    expect_shell_args("-m", "generateSchema")
    subject.run(options)
  end

  describe "#run" do
    context "when successful" do
      it "returns the requested schema" do
        mock_output(:stdout => [ "<x>Film Schema</x>" ], :stderr => "stderr.info")
        subject.run(options).should == "<x>Film Schema</x>"
      end
    end
  end

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

describe ITunes::Store::Transporter::Command::StatusAll do
  subject { described_class.new({}) }
  let(:options) { create_options(:vendor_id => 123123) }

  it { is_expected.to be_kind_of(ITunes::Store::Transporter::Command::Status) }

  it "uses Transporter's statusAll mode" do
    expect_shell_args("-m", "statusAll", :stdout => fixture("status.vendor_id_123123"))
    subject.run(options)
  end
end

describe ITunes::Store::Transporter::Command::Status do
  # Ugh, issue with stubbed print_stdout test, we need XML here :(
  #it_behaves_like "a transporter mode"
  it_behaves_like "a command that accepts a shortname argument"
  it_behaves_like "a command that accepts an itc_provider argument"

  subject { described_class.new({}) }
  let(:options) { create_options(:vendor_id => 123123) }

  it "uses Transporter's status mode" do
    expect_shell_args("-m", "status", :stdout => fixture("status.vendor_id_123123"))
    subject.run(options)
  end

  it "uses Transporter's XML output format" do
    expect_shell_args("-outputFormat", "xml", :stdout => fixture("status.vendor_id_123123"))
    subject.run(options)
  end

  describe "#run" do
    context "when successful" do
      context "with a single id" do
        it "returns the status information for the package" do
          mock_output(:stdout => "status.vendor_id_123123", :stderr => "stderr.info")
          expect(subject.run(options)).to eq [
            :apple_id=>"X9123X",
            :vendor_id=>"123123",
            :content_status=>
            {:status=>"Unpolished",
             :review_status=>"Ready-NotReviewed",
             :itunes_connect_status=>"Other",
             :store_status=>
             {:not_on_store=>[], :on_store=>[], :ready_for_store=>["US"]},
             :video_components=>
             [{:name=>"Video",
               :locale=>nil,
               :status=>"In Review",
               :delivered=>"2011-11-30 01:41:10"},
              {:name=>"Audio",
               :locale=>"en-US",
               :status=>"In Review",
               :delivered=>"2011-11-30 01:41:10"}]},
            :info=>[{:created=>"2016-11-25 10:38:09", :status=>"Imported"}]
          ]
        end
      end

      context "with multiple ids" do
        it "returns all the status information for all packages" do
          options[:vendor_id] = %w[123123 ABCABC]
          mock_output(:stdout => "status.vendor_id_123123_and_ABCABC", :stderr => "stderr.info")
          expect(subject.run(options)).to eq [
            {:apple_id=>"X9123X",
             :vendor_id=>"123123",
             :content_status=>
             {:status=>"Unpolished",
              :review_status=>"Ready-NotReviewed",
              :itunes_connect_status=>"Other",
              :store_status=>
              {:not_on_store=>[], :on_store=>[], :ready_for_store=>["US"]},
              :video_components=>
              [{:name=>"Video",
                :locale=>nil,
                :status=>"In Review",
                :delivered=>"2011-11-30 01:41:10"},
               {:name=>"Audio",
                :locale=>"en-US",
                :status=>"In Review",
                :delivered=>"2011-11-30 01:41:10"}]},
             :info=>[{:created=>"2016-11-25 10:38:09", :status=>"Imported"}]},
            {:apple_id=>"919191",
             :vendor_id=>"ABCABC",
             :content_status=>
             {:status=>"Unpolished",
              :review_status=>"Ready-NotReviewed",
              :itunes_connect_status=>"Other",
              :store_status=>
              {:not_on_store=>[], :on_store=>["US","MX"], :ready_for_store=>["US"]},
              :video_components=>
              [{:name=>"Preview Film",
                :locale=>"World",
                :status=>"Approved",
                :delivered=>"2016-11-25 12:92:46"},
               {:name=>"Audio",
                :locale=>"en-US",
                :status=>"Approved",
                :delivered=>"2016-11-25 12:11:07"},
               {:name=>"Chapters",
                :locale=>"en-US",
                :status=>"Approved",
                :delivered=>"2016-11-25 12:12:46"}]},
             :info=>
             [{:created=>"2011-08-25 10:50:09", :status=>"Imported"},
              {:created=>"2012-11-08 08:26:11", :status=>"Imported"},
              {:created=>"2013-10-31 05:55:29", :status=>"Imported"},
              {:created=>"2014-11-25 10:38:09", :status=>"Imported"}]}
          ]
        end
      end
    end
  end

  describe "options" do
    describe ":vendor_id" do
      context "given a single vendor_id" do
        it "passes a single id to the transporter" do
          expect_shell_args("-vendor_ids", "123", :stdout => fixture("status.vendor_id_123123"))
          subject.run(options.merge(:vendor_id => "123"))
        end
      end

      context "given multiple vendor_ids" do
        it "passes a single id to the transporter" do
          expect_shell_args("-vendor_ids", "123,456", :stdout => fixture("status.vendor_id_123123"))
          subject.run(options.merge(:vendor_id => %w[123 456]))
        end
      end
    end
  end
end

describe ITunes::Store::Transporter::Command::Verify do
  it_behaves_like "a transporter mode"
  it_behaves_like "a command that requires a package argument"
  it_behaves_like "a command that accepts a shortname argument"
  it_behaves_like "a command that accepts an itc_provider argument"

  subject { described_class.new({}) }
  let(:options) { create_options(:package => create_package) }

  it "uses Transporter's verify mode" do
    expect_shell_args("-m", "verify")
    subject.run(options)
  end

  describe "#run" do
    context "when successful" do  #successful means exit(0)
      context "without any errors" do
        it "returns true" do
          mock_output(:stdout => "stdout.success", :stderr => "stderr.info")
          expect(subject.run(options)).to be true
        end
      end

      context "with errors" do
        it "raises an ExecutionError" do
          # If no packages were verfied it exits with 0 but emits an error message
          mock_output(:exit => 0, :stderr => "stderr.errors");
          expect { subject.run(options) }.to raise_exception(ITunes::Store::Transporter::ExecutionError)
        end
      end
    end
  end

  describe "options" do
    describe ":verify_assets" do
      context "when true" do
        it "does not create the command line argument" do
          allow_any_instance_of(ITunes::Store::Transporter::Shell).to receive(:exec) { |shell, arg| expect(arg).not_to include("-disableAssetVerification"); 0 }
          subject.run(options.merge(:verify_assets => true))
        end
      end

      context "when false" do
        it "creates the command line argument" do
          expect_shell_args("-disableAssetVerification")
          subject.run(options.merge(:verify_assets => false))
        end
      end
    end
  end
end

describe ITunes::Store::Transporter::Command::Version do
  subject { described_class.new({}) }

  def output_version(v)
    ["iTMSTransporter version #{v}\n"]
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
