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
  s.add_development_dependency "rake", "~> 0.9.2"
  s.add_development_dependency "rspec", "~> 2.9", "< 3"
  s.add_development_dependency "sdoc"
  s.post_install_message =<<-MSG

  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !!          ATTENTION WINDOWS USERS             !!
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  You must make a small change to the iTMSTransporter.CMD batch file, otherwise
  this library will not function correctly.

  For details see: http://github.com/sshaw/itunes_store_transporter#running-on-windows

  MSG
end
