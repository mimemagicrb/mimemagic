task :default => :test

desc 'Run tests with bacon'
task :test => FileList['test/*_test.rb'] do |t|
  sh "bacon -q -Ilib:test #{t.prerequisites.join(' ')}"
end
