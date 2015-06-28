require "spec_helper"
require "rbconfig"

describe ITunes::Store::Transporter::Shell do
  it "yields stdout and stderr as they become available" do
    ruby = File.join(RbConfig::CONFIG["bindir"], RbConfig::CONFIG["ruby_install_name"])
    temp = Tempfile.new ""
    # sleep else poll() (select) can favor the 1st FD in the read array, causing the
    # test to fail on some platforms
    temp.write(<<-CODE)
      $stdout.puts "OUT 1"
      $stdout.flush
      sleep 1
      $stderr.puts "ERR 1"
      $stderr.flush
      sleep 1
      $stdout.puts "OUT 2"
      $stdout.flush
      sleep 1
      $stderr.puts "ERR 2"
    CODE

    temp.flush

    output = []
    expect = [ [ :stdout, "OUT 1" ],
               [ :stderr, "ERR 1" ],
               [ :stdout, "OUT 2" ],
               [ :stderr, "ERR 2" ] ]

    described_class.new(ruby).exec([temp.path]) do |line, stream|
      output << [ stream, line.chomp! ]
    end

    expect(output).to eq expect
  end

  describe "#exec" do
    it "requires a block" do
      expect { described_class.new.exec([]) }.to raise_exception(ArgumentError, "block required")
    end
  end

  context "when on Windows" do
    before(:all) { ENV["PROGRAMFILES"] = "C:\\" }

    it "selects the Windows executable" do
      allow(described_class).to receive(:windows?).and_return(true)
      allow(described_class).to receive(:osx?).and_return(false)
      expect(described_class.new.path).to match /#{described_class::WINDOWS_EXE}\z/
    end
  end

  context "when on OS X" do
    before do
      allow(described_class).to receive(:windows?).and_return(false)
      allow(described_class).to receive(:osx?).and_return(true)
    end

    it "selects the right executable" do
      exe = described_class::OSX_APPLICATION_LOADER_PATHS.first
      allow(File).to receive(:exist?).and_return(true)
      expect(described_class.new.path).to eq exe
    end

    context "and no OS X specific executable is found" do
      it "defaults to the *nix executable" do
        allow(File).to receive(:exist?).and_return(false)
        expect(described_class.new.path).to eq described_class::DEFAULT_UNIX_PATH
      end
    end
  end

  context "when not on Windows or OS X" do
    it "selects the right executable" do
      allow(described_class).to receive(:windows?).and_return(false)
      allow(described_class).to receive(:osx?).and_return(false)
      expect(described_class.new.path).to match /#{described_class::EXE_NAME}\z/
    end
  end
end
