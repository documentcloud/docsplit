require 'test_helper'
require 'tmpdir'

class ExtractTextTest < Test::Unit::TestCase

  FULL_TEXT = <<-EOTEXT
Gem::Specification.new do |s| s.name = 'pdf-pieces' s.version = '0.1.0' s.date = '2009-11-29'

# Keep version in sync with jammit.rb

s.homepage = "http://documentcloud.github.com/pdf-pieces/" s.summary = "" s.description = <<-EOS EOS s.authors = ['Jeremy Ashkenas'] s.email = 'jeremy@documentcloud.org' s.rubyforge_project = 'pdf-pieces' s.require_paths s.executables s.has_rdoc s.extra_rdoc_files s.rdoc_options = ['lib'] = ['pdf-pieces'] = true = ['README'] << '--title' '--exclude' '--main' '--all'

<< 'PDF Pieces' << << 'test' << << 'README' <<

s.files = Dir['build/*', 'lib/**/*', 'bin/*', 'vendor/*', 'pdf-pieces.gemspec', 'LICENSE', 'README'] end
EOTEXT

  def test_full_text_extraction
    Docsplit.extract_text('test/fixtures/encrypted.pdf', :output => OUTPUT)
    assert FULL_TEXT.strip == File.read("#{OUTPUT}/encrypted.txt").strip
  end

  def test_paged_extraction
    Docsplit.extract_text('test/fixtures/obama_arts.pdf', :pages => 'all', :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.txt"].length == 2
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
    Docsplit.extract_text('test/fixtures/unicode.pdf', :pages => 'all', :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.txt"].length == 3
  end
  
  def test_password_protected
    assert_raises(ExtractionFailed) do
      Docsplit.extract_text('test/fixtures/completely_encrypted.pdf')
    end
  end

end
