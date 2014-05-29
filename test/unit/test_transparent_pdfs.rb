here = File.expand_path(File.dirname(__FILE__))
require File.join(here, '..', 'test_helper')
require 'tmpdir'

class TransparentPDFsTest < Test::Unit::TestCase

  def setup
    @klass = Class.new
    @klass.send(:include, Docsplit::TransparentPDFs)
    @detector = @klass.new
  end

  def test_files_with_pdf_extension_are_always_considered_a_pdf
    pdfs = Dir.glob('test/fixtures/with_pdf_extension/*.pdf').select { |path| File.file?(path) }
    assert pdfs.any?, 'ensure pdfs with extensions are available to test with'
    pdfs.each do |pdf|
      assert @detector.is_pdf?(pdf), "#{pdf} with '.pdf' extension is identified as a PDF (regardless of its file contents)"
    end
  end

  def test_pdfs_without_the_pdf_file_extension_is_considerd_a_pdf
    pdfs = Dir.glob('test/fixtures/without_pdf_extension/*/*').select { |path| File.file?(path) }
    assert pdfs.any?, 'ensure pdfs without extensions are available to test with'
    pdfs.each do |pdf|
      assert @detector.is_pdf?(pdf), "#{pdf} with '.pdf' extension is identified as a PDF"
    end
  end

end
