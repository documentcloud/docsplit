require 'test_helper'

class ConvertToPdfTest < Test::Unit::TestCase

  def test_doc_conversion
    Docsplit.extract_pdf('test/fixtures/obama_veterans.doc', :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.pdf"] == ["#{OUTPUT}/obama_veterans.pdf"]
  end

  def test_rtf_conversion
    Docsplit.extract_pdf('test/fixtures/obama_hopes.rtf', :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.pdf"] == ["#{OUTPUT}/obama_hopes.pdf"]
  end

  def test_conversion_then_page_extraction
    Docsplit.extract_pdf('test/fixtures/obama_veterans.doc', :output => OUTPUT)
    Docsplit.extract_pages("#{OUTPUT}/obama_veterans.pdf", :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.pdf"].length == 8
  end

end
