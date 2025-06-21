require "rspec"
require "rspec/its"
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
    output = expected.last.is_a?(Hash) ? expected.pop : {}
    allow_any_instance_of(ITunes::Store::Transporter::Shell).to receive(:exec) do |shell, argv, &block|
      expect(argv).to include(*expected)

      [:stdout, :stderr].each do |fd|
        next unless output[fd]
        output[fd].each { |line| block.call(line, fd) }
      end

      0
    end
  end

  def fixture(path)
    Fixture.for(path)
  end

  # Set up output streams and exit code
  def mock_output(options = {})
    outputs = []
    exitcode = options[:exit] || 0

    # Load a fixture for the given stream
    [:stderr, :stdout].each do |fd|
      fixture = options[fd]
      next unless fixture

      lines = Array === fixture ? fixture : Fixture.for(fixture)
      outputs << [ lines, fd ]
    end

    allow_any_instance_of(ITunes::Store::Transporter::Shell).to receive(:exec) do |shell, argv, &block|
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
  
  # Enable old should syntax for backward compatibility
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  
  # Enable old mock syntax for backward compatibility  
  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end
