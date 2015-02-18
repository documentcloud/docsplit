here = File.expand_path(File.dirname(__FILE__))
require File.join(here, '..', 'test_helper')

class ExtractImagesTest < Minitest::Test

  def test_basic_image_extraction
    Docsplit.extract_images('test/fixtures/obama_arts.pdf', :format => :gif, :size => "250x", :output => OUTPUT)
    assert_directory_contains(OUTPUT, ['obama_arts_1.gif', 'obama_arts_2.gif'])
  end

  def test_image_formatting
    Docsplit.extract_images('test/fixtures/obama_arts.pdf', :format => [:jpg, :gif], :size => "250x", :output => OUTPUT)
    assert_equal 2, Dir["#{OUTPUT}/*.gif"].length
    assert_equal 2, Dir["#{OUTPUT}/*.jpg"].length
  end

  def test_page_ranges
    Docsplit.extract_images('test/fixtures/obama_arts.pdf', :format => :gif, :size => "50x", :pages => 2, :output => OUTPUT)
    assert_equal ["#{OUTPUT}/obama_arts_2.gif"], Dir["#{OUTPUT}/*.gif"]
  end

  def test_image_sizes
    Docsplit.extract_images('test/fixtures/obama_arts.pdf', :format => :gif, :rolling => true, :size => ["150x", "50x"], :output => OUTPUT)
    assert_operator File.size("#{OUTPUT}/50x/obama_arts_1.gif"), :<, File.size("#{OUTPUT}/150x/obama_arts_1.gif")
  end

  def test_encrypted_images
    Docsplit.extract_images('test/fixtures/encrypted.pdf', :format => :gif, :size => "50x", :output => OUTPUT)
    assert_operator File.size("#{OUTPUT}/encrypted_1.gif"), :>, 100
  end

  def test_password_protected_extraction
    assert_raises(ExtractionFailed) do
      Docsplit.extract_images('test/fixtures/completely_encrypted.pdf')
    end
  end

  def test_repeated_extraction_in_the_same_directory
    Docsplit.extract_images('test/fixtures/obama_arts.pdf', :format => :gif, :size => "250x", :output => OUTPUT)
    assert_directory_contains(OUTPUT, ['obama_arts_1.gif', 'obama_arts_2.gif'])
    Docsplit.extract_images('test/fixtures/obama_arts.pdf', :format => :gif, :size => "250x", :output => OUTPUT)
    assert_directory_contains(OUTPUT, ['obama_arts_1.gif', 'obama_arts_2.gif'])
  end

  def test_name_escaping_while_extracting_images
    Docsplit.extract_images('test/fixtures/PDF file with spaces \'single\' and "double quotes".pdf', :format => :gif, :size => "250x", :output => OUTPUT)
    assert_directory_contains(OUTPUT, ['PDF file with spaces \'single\' and "double quotes"_1.gif',
                                       'PDF file with spaces \'single\' and "double quotes"_1.gif'])
  end

end
