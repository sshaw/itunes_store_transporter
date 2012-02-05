require "spec_helper"
require "rbconfig"

describe ITunes::Store::Transporter::Shell do  
  it "yields stdout and stderr as they become available" do 
    ruby = File.join(Config::CONFIG["bindir"], Config::CONFIG["ruby_install_name"])
    temp = Tempfile.new ""
    temp.write(<<-CODE)
      $stdout.sync = true
      $stderr.sync = true
      $stdout.puts "OUT 1"
      $stderr.puts "ERR 1"
      $stdout.puts "OUT 2"
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

    output.should == expect
  end

  context "when on Windows" do 
    before(:all) { ENV["PROGRAMFILES"] = "C:\\" }
    it "selects the Windows executable" do 
      described_class.stub(:windows? => true)
      described_class.new.path.should match /#{described_class::WINDOWS_EXE}\Z/
    end
  end

  context "when on anything but Windows" do 
    it "selects the right executable" do 
      described_class.stub(:windows? => false)
      described_class.new.path.should match /#{described_class::EXE_NAME}\Z/
    end
  end
end
