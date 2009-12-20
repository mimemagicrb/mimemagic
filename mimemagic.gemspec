# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{mimemagic}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Daniel Mendler"]
  s.date = %q{2009-05-09}
  s.email = ["mail@daniel-mendler.de"]
  s.files = ["lib/mimemagic.rb", "lib/mimemagic_tables.rb", "test/test_mimemagic.rb", "script/freedesktop.org.xml", "script/generate-mime.rb", "Rakefile"]
  s.has_rdoc = true
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{mimemagic}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Mime detection by extension or content}
  s.homepage = 'https://github.com/minad/mimemagic'
  s.test_files = ["test/test_mimemagic.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe>, [">= 1.8.3"])
    else
      s.add_dependency(%q<hoe>, [">= 1.8.3"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 1.8.3"])
  end
end

