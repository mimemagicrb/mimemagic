# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/lib/mimemagic/version'
require 'date'

Gem::Specification.new do |s|
  s.name = 'mimemagic'
  s.version = MimeMagic::VERSION

  s.authors = ['Daniel Mendler']
  s.date = Date.today.to_s
  s.email = ['mail@daniel-mendler.de']

  s.files         = `git ls-files`.split("\n")
  s.require_paths = %w(lib)

  s.rubyforge_project = s.name
  s.summary = 'Mime detection by extension or content'
  s.homepage = 'https://github.com/minad/mimemagic'

  s.add_development_dependency('bacon')
  s.add_development_dependency('rake')
end
