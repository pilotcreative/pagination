# -*- encoding: utf-8 -*-
require File.expand_path("../lib/pagination/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "pagination"
  s.version     = Pagination::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Mateusz Drożdżyński"]
  s.email       = ["gems@objectreload.com"]
  s.homepage    = "http://github.com/objectreload/pagination"
  s.summary     = "Simple pagination - without changes in controllers"

  s.required_rubygems_version = ">= 1.3.6"

  s.add_development_dependency "bundler", ">= 1.0.0"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end
