require 'test_helper'

class ExtractInfoTest < Test::Unit::TestCase

  def test_title
    assert "PDF Pieces" == DocSplit.extract_title('test/fixtures/encrypted.pdf')
  end

  def test_doc_title
    assert "Remarks of President Barack Obama" == DocSplit.extract_title('test/fixtures/obama_veterans.doc')
  end

  def test_author
    assert "Jeremy Ashkenas" == DocSplit.extract_author('test/fixtures/encrypted.pdf')
  end

  def test_date
    assert "2007-11-29" == DocSplit.extract_date('test/fixtures/obama_arts.pdf')
  end

  def test_length
    assert 2 == DocSplit.extract_length('test/fixtures/obama_arts.pdf')
  end

  def test_producer
    assert "Mac OS X 10.6.2 Quartz PDFContext" == DocSplit.extract_producer('test/fixtures/encrypted.pdf')
  end

  def test_password_protected
    assert_raises(ExtractionFailed) do
      DocSplit.extract_author('test/fixtures/completely_encrypted.pdf')
    end
  end

end
