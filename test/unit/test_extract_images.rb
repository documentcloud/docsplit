require 'test_helper'

class ExtractImagesTest < Test::Unit::TestCase

  def test_basic_image_extraction
    Docsplit.extract_images('test/fixtures/obama_arts.pdf', :format => :gif, :size => "250x", :output => OUTPUT)
    assert_directory_contains(OUTPUT, ['obama_arts_1.gif', 'obama_arts_2.gif'])
  end

  def test_image_formatting
    Docsplit.extract_images('test/fixtures/obama_arts.pdf', :format => [:jpg, :gif], :size => "250x", :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.gif"].length == 2
    assert Dir["#{OUTPUT}/*.jpg"].length == 2
  end
  def test_image_extraction_specifying_return_value
    def images_present?(formats, val)
      formats.map do |format|
        val.any?(Regexp.new(format))
      end.reduce(&:and)
    end
    pdf_path = 'test/fixtures/obama_arts.pdf'
    ret_value = Docsplit.extract_images(pdf_path, :format => [:jpg, :gif], :size => "250x", :output => OUTPUT, :and_return => [:images])
    assert ret_value.length == 2

    ret_value = Docsplit.extract_images(pdf_path, :format => [:jpg, :gif], :size => "250x 50x", :output => OUTPUT, :and_return => [:images])
    assert ret_value.length == 4
    assert images_present([:jpg, :gif], ret_value)
   
     intermediate_ret_value = Docsplit.extract_images(pdf_path, :format => [:jpg, :gif], :size => "250x 50x", :output => OUTPUT, :and_return => [:intermediate])
    assert intermediate_ret_value.length == 1
    assert !images_present?([:jpg, :gif], intermediate_ret_value)
    assert intermediate.ret_value.any?(/\.pdf/)

    non_specified_ret_value = Docsplit.extract_images(pdf_path, :format => [:jpg, :gif], :size => "250x 50x", :output => OUTPUT)
    assert non_specified_ret_value.lenght == 1
    assert !images_present?([:jpg, :gif], intermediate_ret_value)
    assert non_specified_ret_value == intermediate_ret_value

  end

  def test_page_ranges
    Docsplit.extract_images('test/fixtures/obama_arts.pdf', :format => :gif, :size => "50x", :pages => 2, :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.gif"] == ["#{OUTPUT}/obama_arts_2.gif"]
  end

  def test_image_sizes
    Docsplit.extract_images('test/fixtures/obama_arts.pdf', :format => :gif, :rolling => true, :size => ["150x", "50x"], :output => OUTPUT)
    assert File.size("#{OUTPUT}/50x/obama_arts_1.gif") < File.size("#{OUTPUT}/150x/obama_arts_1.gif")
  end

  def test_encrypted_images
    Docsplit.extract_images('test/fixtures/encrypted.pdf', :format => :gif, :size => "50x", :output => OUTPUT)
    assert File.size("#{OUTPUT}/encrypted_1.gif") > 100
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
