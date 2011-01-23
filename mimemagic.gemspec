# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{mimemagic}
  s.version = "0.1.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Daniel Mendler"]
  s.date = %q{2009-05-09}
  s.email = ["mail@daniel-mendler.de"]
  s.files = %w{
lib/mimemagic.rb
lib/mimemagic_tables.rb
test/mimemagic_test.rb
test/files/application.x-bzip
test/files/image.jpeg
test/files/image.png
test/files/application.x-tar
test/files/application.x-gzip
test/files/application.zip
test/files/application.x-ruby
script/freedesktop.org.xml
script/generate-mime.rb
Rakefile
README
  }
  s.has_rdoc = true
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{mimemagic}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Mime detection by extension or content}
  s.homepage = 'https://github.com/minad/mimemagic'
  s.test_files = ["test/mimemagic_test.rb"]
  s.add_development_dependency('bacon')
end
