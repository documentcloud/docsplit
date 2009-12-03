require 'fileutils'
require 'rake/testtask'

desc 'Run all tests'
task :test do
  $LOAD_PATH.unshift(File.expand_path('test'))
  require 'redgreen' if Gem.available?('redgreen')
  require 'test/unit'
  Dir['test/*/**/test_*.rb'].each {|test| require test }
end

desc 'Clean the compiled Java classes'
task :clean do
  FileUtils.rm_r('build') if File.exists?('build')
  Dir.mkdir('build')
end

desc 'Build all Java command-line clients'
task :build => :clean do
  sh "javac -cp vendor/'*' -d build -Xlint -Xlint:-path lib/docsplit/*.java"
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
