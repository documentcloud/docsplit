require 'fileutils'
require 'rake/testtask'

desc 'Run all tests'
task :test do
  require 'minitest/autorun'
  Dir['./test/*/**/test_*.rb'].each {|test| require test }
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
