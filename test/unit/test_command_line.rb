here = File.expand_path(File.dirname(__FILE__))
require File.join(here, '..', 'test_helper')
require "#{Docsplit::ROOT}/lib/docsplit/command_line"

class ConvertToPdfTest < Minitest::Test

  def test_page_cli_parsing
    input = "1,3-6,9,12,2,3"
    output = Docsplit::CommandLine.format_page_param(input)
    assert_equal [1,2,3,4,5,6,9,12], output

    input = "3"
    output = Docsplit::CommandLine.format_page_param(input)
    assert_equal [3], output

    input = "3-6"
    output = Docsplit::CommandLine.format_page_param(input)
    assert_equal [3, 4, 5, 6], output

    input = "2,4,6,8"
    output = Docsplit::CommandLine.format_page_param(input)
    assert_equal [2, 4, 6, 8], output
  end

end
