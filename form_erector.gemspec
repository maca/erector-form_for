# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "erector/form_for/version"

Gem::Specification.new do |s|
  s.name        = "erector-form_for"
  s.version     = FormErector::VERSION
  s.authors     = ["Macario"]
  s.email       = ["macarui@gmail.com"]
  s.homepage    = "http://github.com/maca/erector-form_for"
  s.summary     = %q{Form helper inspired by erector targeting html5}
  s.description = %q{Form helper inspired by erector targeting html5}

  s.rubyforge_project = "erector-form_for"
  
  s.add_dependency 'erector'
  s.add_dependency 'sinatra'
  s.add_dependency 'sinatra-trails'
  s.add_dependency 'i18n'
  s.add_dependency 'activesupport', '>= 3.0'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rack_csrf'
  s.add_development_dependency 'sequel'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'sinatra-r18n'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
