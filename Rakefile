require 'fileutils'
require 'rake/testtask'

desc 'Run all tests'
task :test do
  $LOAD_PATH.unshift(File.expand_path('test'))

  require 'test/unit'
  Dir['test/*/**/test_*.rb'].each do |test|
    require File.join(File.dirname(__FILE__), test)
  end
end

namespace :gem do

  desc 'Build and install the docsplit gem'
  task :install do
    sh "gem build docsplit.gemspec"
    sh "sudo gem install #{Dir['*.gem'].join(' ')} --local --no-ri --no-rdoc"
  end

  desc 'Uninstall the docsplit gem'
  task :uninstall do
    sh "sudo gem uninstall -x docsplit"
  end

end

task :default => :test
