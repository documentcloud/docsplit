require 'fileutils'
require 'rake/testtask'
require 'bundler/gem_tasks'

desc 'Run all tests'
task :test do
  require 'minitest/autorun'
  Dir['./test/*/**/test_*.rb'].each {|test| require test }
end

task :default => :test
