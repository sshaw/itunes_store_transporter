require "rake"
require "spec/rake/spectask"

Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList["spec/**/*.rb"]
end

task :default => "spec"
