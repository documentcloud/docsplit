here = File.expand_path(File.dirname(__FILE__))
require File.join(here, '..', 'test_helper')

class ExtractPagesTest < Test::Unit::TestCase

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

  def test_leading_zeros_while_extracting_pages
    Docsplit.extract_pages('test/fixtures/leading_zeros.pdf', :leading_zeros => true, :output => OUTPUT)

    doc_data_path = File.join(OUTPUT, 'doc_data.txt')
    File.delete(doc_data_path) if File.exists?(doc_data_path)

    assert_directory_contains(OUTPUT, ['leading_zeros_01.pdf', 'leading_zeros_02.pdf',
                                       'leading_zeros_03.pdf', 'leading_zeros_04.pdf',
                                       'leading_zeros_05.pdf', 'leading_zeros_06.pdf',
                                       'leading_zeros_07.pdf', 'leading_zeros_08.pdf',
                                       'leading_zeros_09.pdf', 'leading_zeros_10.pdf'])
  end

end
