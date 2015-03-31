require "rake"
require "rspec/core/rake_task"
require "itunes/store/transporter/output_parser"

RSpec::Core::RakeTask.new(:spec)

task :default => "spec"

desc "parse iTMSTransporter output given via stdin"
task :parse_output do

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
