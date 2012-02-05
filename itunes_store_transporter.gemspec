require "itunes/store/transporter/version"

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
  s.email       = "sshaw@lucas.cis.temple.edu"
  s.files       = Dir["lib/**/*.rb", "README.rdoc"]
  s.test_files  = Dir["spec/**/*.rb"]
  s.homepage    = "http://github.com/sshaw/itunes_store_transporter"
  s.license     = "MIT"
  s.add_dependency "childprocess", "~> 0.3.0"
  s.add_dependency "optout", "~> 0.0.2"
  s.add_development_dependency "rake", "~> 0.9.2"
  s.add_development_dependency "rspec", "~> 2.8.0"
  s.extra_rdoc_files = ["README.rdoc"]
end
