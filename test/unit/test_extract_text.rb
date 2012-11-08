require 'test_helper'
require 'tmpdir'

class ExtractTextTest < Test::Unit::TestCase

  def test_paged_extraction
    return_value = Docsplit.extract_text('test/fixtures/obama_arts.pdf', :pages => 'all', :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.txt"].length == 2
    assert File.read("#{OUTPUT}/obama_arts_1.txt").match("Paid for by Obama for America")
    assert return_value.is_a?(Enumerable)
    assert return_value.all?{|val| val =~ /\.txt/}
    assert return_value.length == 2
  end

  def test_page_only_extraction
    Docsplit.extract_text('test/fixtures/obama_arts.pdf', :pages => 2..2, :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.txt"] == ["#{OUTPUT}/obama_arts_2.txt"]
  end

  def test_capitalized_pdf_extraction
    Dir["#{OUTPUT}/*.txt"].each {|previous| FileUtils.rm(previous) }
    Dir.mktmpdir do |dir|
      FileUtils.cp('test/fixtures/obama_arts.pdf', "#{dir}/OBAMA_ARTS.PDF")
      Docsplit.extract_text("#{dir}/OBAMA_ARTS.PDF", :pages => 2..2, :output => OUTPUT)
    end
    assert Dir["#{OUTPUT}/*.txt"] == ["#{OUTPUT}/OBAMA_ARTS_2.txt"]
  end

  def test_unicode_extraction
    return_value = Docsplit.extract_text('test/fixtures/unicode.pdf', :pages => 'all', :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.txt"].length == 3
    assert return_value.is_a?(Enumerable)
    assert return_value.all?{|val| val =~ /\.txt/}
    assert return_value.length == 3
  end

  def test_ocr_extraction
    return_value =Docsplit.extract_text('test/fixtures/corrosion.pdf', :pages => 'all', :output => OUTPUT)
    4.times do |i|
      file = "corrosion_#{i + 1}.txt"
      assert_directory_contains(OUTPUT, file)
      assert File.read(File.join(OUTPUT, file)).size > 1, "Expected that file with extracted text should have reasonable size"
    end
    assert return_value.is_a?(Enumerable)
    assert return_value.all?(/\.txt/)
  end


  def test_ocr_extraction_in_mock_language
    exception = assert_raise(Docsplit::ExtractionFailed) {Docsplit.extract_text('test/fixtures/corrosion.pdf', :pages => 'all', :output => OUTPUT, :language => "mock")}
    assert exception.message.match("tessdata/mock"), "Expected problem with loading data for language 'mock'"
  end

  def test_password_protected
    assert_raises(ExtractionFailed) do
      Docsplit.extract_text('test/fixtures/completely_encrypted.pdf')
    end
  end

  def test_name_escaping_while_extracting_text
    Docsplit.extract_text('test/fixtures/PDF file with spaces \'single\' and "double quotes".pdf', :pages => 'all', :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.txt"].length == 2
  end

end
