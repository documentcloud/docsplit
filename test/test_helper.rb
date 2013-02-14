here = File.dirname(__FILE__)
require File.join(here, '..', 'lib', 'docsplit')
require 'fileutils'

class Test::Unit::TestCase
  include Docsplit

  OUTPUT = 'test/output'

  def clear_output
    FileUtils.rm_r(OUTPUT) if File.exists?(OUTPUT)
  end

  def teardown
    clear_output
  end

  def assert_directory_contains(dir, files)
    files_in_directory = Dir["#{dir}/*"]
    if files.kind_of?(Array)
      assert files_in_directory.length == files.length, "Expected directory to contain exactly #{files.length} files"
    else
      files = [files]
    end
    files.each { |f| assert files_in_directory.include?(File.join(dir, f)), "Expected directory #{dir} to contain file #{f}, but it contains #{files_in_directory.inspect}" }
  end
end
