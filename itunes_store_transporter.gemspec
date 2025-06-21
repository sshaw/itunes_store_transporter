require File.expand_path("../lib/itunes/store/transporter/version", __FILE__)
require "date"

Gem::Specification.new do |s|
  s.name        = "itunes_store_transporter"
  s.version     = ITunes::Store::Transporter::VERSION
  s.date        = Date.today
  s.summary     = "Upload and manage your assets in the iTunes Store using the iTunes Store's Transporter (iTMSTransporter)."
  s.description =<<-DESC
    iTunes::Store::Transporter is a wrapper around Apple's iTMSTransporter program. It allows you to upload packages to the
    Apple Store, validate them, retrieve status information, lookup metadata, and more!
  DESC
  s.authors     = ["Skye Shaw"]
  s.email       = "skye.shaw@gmail.com"
  s.executables  << "itms"
  s.test_files  = Dir["spec/**/*.*"]
  s.extra_rdoc_files = %w[README.rdoc Changes]
  s.files       = Dir["lib/**/*.rb"] + s.test_files + s.extra_rdoc_files
  s.homepage    = "http://github.com/sshaw/itunes_store_transporter"
  s.license     = "MIT"
  s.add_dependency "childprocess", "~> 0.3.2"
  s.add_dependency "optout", "~> 0.0.2"
  s.add_dependency "rexml", "~> 3.2"
  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "rspec", "~> 3.12"
  s.add_development_dependency "rspec-its", "~> 1.3"
end
