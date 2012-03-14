require "rspec"
require "yaml"
require "tempfile"
require "fileutils"
require "itunes/store/transporter"

module SpecHelper
  def create_options(options = {})
    { :username => "uzer", 
      :password => "_Gcod3" }.merge(options)
  end
  
  # TODO: options for package contents?
  def create_package(options = {})
    Dir.mktmpdir ["",".itmsp"]
  end

  def expect_shell_args(*expected)    
    ITunes::Store::Transporter::Shell.any_instance.stub(:exec) { |*arg| arg.first.should include(*expected) } 
  end

  def fixture(path)
    Fixture.for(path)
  end
  
  def mock_output(options = {})
    outputs = []
    exitcode = options[:exit] || 0
    
    [:stderr, :stdout].each do |fd|
      fixture = options[fd]
      next unless fixture
      lines = Array === fixture ? fixture : Fixture.for(fixture)
      outputs << [ lines, fd ]
    end
    
    ITunes::Store::Transporter::Shell.any_instance.stub(:exec) do |*options|
      block = options.pop
      outputs.each do |lines, fd|
        lines.each { |line| block.call(line, fd) }
      end
      exitcode
    end
  end
  
  module Fixture
    class << self
      def for(path)      
        type, name = path.split ".", 2
        raise "Unknown fixture '#{path}'" unless fixtures[type].include?(name)
        fixtures[type][name].split("\n")
      end
      
      private
      def fixtures
        @fixtures ||= load_fixtures
      end
      
      def load_fixtures
        init = Hash.new { |h, k| h[k] = {} }
        Dir[File.join(File.expand_path(File.dirname(__FILE__)), "fixtures", "*.yml")].inject(init) do |fixtures, path|
          name = File.basename(path, ".yml")
          fixtures[name] = YAML.load_file(path)
          fixtures
        end
      end
    end
  end 
end  

RSpec.configure do |config| 
  config.include(SpecHelper)
end
