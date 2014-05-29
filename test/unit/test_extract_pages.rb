here = File.expand_path(File.dirname(__FILE__))
require File.join(here, '..', 'test_helper')

class ExtractPagesTest < Minitest::Test

  def test_multi_page_extraction
    Docsplit.extract_pages('test/fixtures/obama_arts.pdf', :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.pdf"].length == 2
  end

  def test_password_protected
    assert_raises(ExtractionFailed) do
      Docsplit.extract_pages('test/fixtures/completely_encrypted.pdf')
    end
  end

  def test_doc_page_extraction
    Docsplit.extract_pages('test/fixtures/obama_veterans.doc', :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.pdf"].length == 7
  end

  def test_name_escaping_while_extracting_pages
    Docsplit.extract_pages('test/fixtures/PDF file with spaces \'single\' and "double quotes".pdf', :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.pdf"].length == 2
  end

end
