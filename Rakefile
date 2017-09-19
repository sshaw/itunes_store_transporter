require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rdoc/task"
require "sdoc"
require "pp"

require "itunes/store/transporter/output_parser"
require "itunes/store/transporter/xml/status"

RSpec::Core::RakeTask.new(:spec)

task :default => "spec"

RDoc::Task.new do |rdoc|
  rdoc.generator = "sdoc"
  rdoc.rdoc_files.include("README.rdoc", "lib/**/*.rb")
end

namespace :parse do
  desc "parse iTMSTransporter output given via stdin"
  task :output do
    print_results = lambda do |name, results|
      print "#{name}:"

      if results.none?
        puts " none"
      else
        print "\n"
        results.each_with_index do |message, i|
          printf "%2d. %s\n", i + 1, message.to_s
        end
      end

      puts "-" * 30
    end

    parser = ITunes::Store::Transporter::OutputParser.new(STDIN.readlines)
    print_results.call("Errors", parser.errors)
    print_results.call("Warnings", parser.warnings)
  end

  namespace :xml do
    desc "parse iTMSTransporter status or statusAll XML, given via stdin"
    task :status do
      pp ITunes::Store::Transporter::XML::Status.new.parse(STDIN)
    end
  end
end
