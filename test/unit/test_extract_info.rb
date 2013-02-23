here = File.expand_path(File.dirname(__FILE__))
require File.join(here, '..', 'test_helper')

class ExtractInfoTest < Test::Unit::TestCase

  def test_title
    assert "PDF Pieces" == Docsplit.extract_title('test/fixtures/encrypted.pdf')
  end

  def test_doc_title
    assert "Remarks of President Barack Obama" == Docsplit.extract_title('test/fixtures/obama_veterans.doc')
  end

  def test_author
    assert "Jeremy Ashkenas" == Docsplit.extract_author('test/fixtures/encrypted.pdf')
  end

  def test_date
    assert "Thu Nov 29 14:54:46 2007" == Docsplit.extract_date('test/fixtures/obama_arts.pdf')
  end

  def test_length
    assert 2 == Docsplit.extract_length('test/fixtures/obama_arts.pdf')
  end

  def test_producer
    assert "Mac OS X 10.6.2 Quartz PDFContext" == Docsplit.extract_producer('test/fixtures/encrypted.pdf')
  end

  def test_password_protected
    assert_raises(ExtractionFailed) do
      Docsplit.extract_author('test/fixtures/completely_encrypted.pdf')
    end
  end

  def test_name_escaping_while_extracting_info
    assert 2 == Docsplit.extract_length('test/fixtures/PDF file with spaces \'single\' and "double quotes".pdf')
  end
  
  def test_malformed_unicode
    assert_nothing_raised do
      Docsplit.extract_date('test/fixtures/Faktura 10.pdf')
    end
  end
  
  def test_extract_all
    metadata = Docsplit.extract_info('test/fixtures/obama_arts.pdf')
    assert metadata[:author] == "mkommareddi"
    assert metadata[:date] == "Thu Nov 29 14:54:46 2007"
    assert metadata[:creator] == "PScript5.dll Version 5.2"
    assert metadata[:producer] == "Acrobat Distiller 8.1.0 (Windows)"
    assert metadata[:title] == "Microsoft Word - Fact Sheet Arts 112907 FINAL.doc"
    assert metadata[:length] == 2
    assert metadata.length == 6
  end

end
