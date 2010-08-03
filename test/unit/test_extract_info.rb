require 'test_helper'

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

end
