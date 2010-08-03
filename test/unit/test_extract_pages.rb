require 'test_helper'

class ExtractPagesTest < Test::Unit::TestCase

  def test_multi_page_extraction
    Docsplit.extract_pages('test/fixtures/obama_arts.pdf', :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.pdf"].length == 2
  end

  def test_single_page_extraction
    Docsplit.extract_pages('test/fixtures/encrypted.pdf', :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.pdf"].length == 1
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

end
