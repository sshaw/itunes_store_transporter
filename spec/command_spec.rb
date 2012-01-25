require "spec_helper"

def create_options(options = {})
  { :username => "uzer", 
    :password => "_Gcod3" }.merge(options)
end

# TODO: options for package contents
def create_package(options = {})
  Dir.mktmpdir ["",".itmsp"]
end

shared_examples_for "a transporter mode" do   
  it { should be_a_kind_of(ITunes::Store::Transporter::Command::Base) }
  it { should be_a_kind_of(ITunes::Store::Transporter::Command::Mode) }
  # or nil
  its(:mode) { should_not be_empty }

  it "requires a username" do 
    proc { subject.run(:password => "pass") }.should raise_error(ITunes::Store::Transporter::OptionError, /username/)
  end
  
  it "requires a password" do 
    proc { subject.run(:username => "user") }.should raise_error(ITunes::Store::Transporter::OptionError, /password/)
  end
end

shared_examples_for "something that requires a package argument" do     
  context "when missing" do 
    it "will raise an OptionError" do 
      options = create_options
      proc { subject.run(options) }.should raise_error(ITunes::Store::Transporter::OptionError, /package/)
    end
  end
  
  context "when given" do 
    before(:all) { @tmpdir = Dir.mktmpdir }
    after(:all) { FileUtils.rm_rf(@tmpdir) }

    it "must be a directory" do 
      path = Tempfile.new("").path
      options = create_options(:package => path)
      proc { subject.run(options) }.should raise_error(ITunes::Store::Transporter::OptionError, /dir/i)
    end  

    it "must be a directory ending in .itmsp" do 
      options = create_options(:package => @tmpdir)
      proc { subject.run(options) }.should raise_error(ITunes::Store::Transporter::OptionError, /dir/i)
    end  
  end
end

describe ITunes::Store::Transporter::Command::Providers do
  it_behaves_like "a transporter mode"

  subject { described_class.new({}) }
  its(:mode) { should == "provider" }
  
  # describe "options" do 
  # end
  
  it "returns the shortname and longname for each provider" do 
    options = create_options
    mock_output(:stdout => "providers.two")    
    subject.run(options).should == [ { :longname => "Some Great User", :shortname => "luser" }, 
                                     { :longname => "Skye's Taco Eating Service Inc.", :shortname => "conmuchacebolla" } ]
  end
end

describe ITunes::Store::Transporter::Command::Upload do
  it_behaves_like "a transporter mode"

  subject { described_class.new({}) }  
  let(:options) { create_options(:package => create_package, 
                                 :shortname => "shorty", 
                                 :protocol => "Aspera")  }

  #before(:all) { @package = create_package  }
  after(:all) { FileUtils.rm_rf(options[:package]) }

  context "when successful" do 
    it "returns true" do 
      mock_output(:stdout => "upload.success")    
      subject.run(options).should be_true
    end
  end

  context "when fails" do  
    it "raises an ExecutionError" do 
      mock_output(:stderr => "upload.failure", :exit => 1)    
      proc { subject.run(options) }.should  raise_exception(ITunes::Store::Transporter::ExecutionError)      
    end
  end
end

describe ITunes::Store::Transporter::Command::Schema do
  it_behaves_like "a transporter mode"

  subject { described_class.new({}) }
  its(:mode) { should == "generateSchema" }
  let(:options) { create_options(:shortname => "shorty", 
                                 :type => "strict", 
                                 :version => "film5") }
 
  it "returns the requested schema" do 
    mock_output(:stdout => "schema.film")    
    subject.run(options).should == "<x>Film Schema</x>"
  end
end

describe ITunes::Store::Transporter::Command::Verify do
  subject { described_class.new({}) }
  it_behaves_like "a transporter mode"
  #it_behaves_like "something that requires a package argument"  
  its(:mode) { should == "verify" }
  
  context "non-zero exit status" do 
  end
end
