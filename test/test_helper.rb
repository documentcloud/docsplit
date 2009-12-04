require 'lib/docsplit'
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

end