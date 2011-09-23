# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "form_erector/version"

Gem::Specification.new do |s|
  s.name        = "form_erector"
  s.version     = FormErector::VERSION
  s.authors     = ["Macario"]
  s.email       = ["macarui@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "form_erector"
  
  s.add_dependency 'erector'
  s.add_dependency 'sinatra'
  s.add_dependency 'sinatra-trails'
  s.add_dependency 'i18n'
  s.add_dependency 'activesupport', '>= 3.0'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'rack-test'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
