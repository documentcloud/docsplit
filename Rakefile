require 'fileutils'
require 'rake/testtask'

desc 'Run all tests'
task :test do
  $LOAD_PATH.unshift(File.expand_path('test'))
  require 'redgreen' if Gem.available?('redgreen')
  require 'test/unit'
  Dir['test/*/**/test_*.rb'].each {|test| require test }
end

desc 'Launch OpenOffice for testing'
task :openoffice do
  sh "/Applications/OpenOffice.org.app/Contents/MacOS/soffice.bin soffice -headless -accept=\"socket,host=127.0.0.1,port=8100;urp;\" -nofirststartwizard"
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
