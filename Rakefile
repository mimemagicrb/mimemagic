task :default => %w(test)

desc 'Run tests with bacon'
task :test => FileList['test/*_test.rb'] do |t|
  sh "bacon -q -Ilib:test #{t.prerequisites.join(' ')}"
end

desc 'Generate mime tables'
task :tables => 'lib/mimemagic_tables.rb'
file 'lib/mimemagic_tables.rb' => FileList['script/freedesktop.org.xml'] do |f|
  sh "script/generate-mime.rb #{f.prerequisites.join(' ')} > #{f.name}"
end

desc 'Generate documentation'
task :doc => 'doc/api/index.html'
file 'doc/api/index.html' => FileList['**/*.rb'] do |f|
  sh "rdoc -o doc/api --title 'Git-Wiki Documentation' --inline-source --format=html #{f.prerequisites.join(' ')}"
end
