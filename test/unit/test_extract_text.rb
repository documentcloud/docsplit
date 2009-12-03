require 'test_helper'

class ExtractTextTest < Test::Unit::TestCase

  FULL_TEXT = <<-EOTEXT
Gem::Specification.new do |s|
  s.name      = 'docsplit'
  s.version   = '0.1.0'         # Keep version in sync with jammit.rb
  s.date      = '2009-11-29'
  s.homepage    = "http://documentcloud.github.com/docsplit/"
  s.summary     = ""
  s.description = <<-EOS
  EOS
  s.authors           = ['Jeremy Ashkenas']
  s.email             = 'jeremy@documentcloud.org'
  s.rubyforge_project = 'docsplit'
  s.require_paths     = ['lib']
  s.executables       = ['docsplit']
  s.has_rdoc          = true
  s.extra_rdoc_files  = ['README']
  s.rdoc_options      << '--title'    << 'PDF Pieces' <<
                         '--exclude'  << 'test' <<
                         '--main'     << 'README' <<
                         '--all'
  s.files = Dir['build/*', 'lib/**/*', 'bin/*', 'vendor/*',
'docsplit.gemspec', 'LICENSE', 'README']
end
  EOTEXT

  def test_full_text_extraction
    DocSplit.extract_text('test/fixtures/encrypted.pdf', :output => OUTPUT)
    assert FULL_TEXT == File.read("#{OUTPUT}/encrypted.txt")
  end

  def test_paged_extraction
    DocSplit.extract_text('test/fixtures/obama_arts.pdf', :pages => 'all', :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.txt"].length == 2
  end

  def test_page_only_extraction
    DocSplit.extract_text('test/fixtures/obama_arts.pdf', :pages => 2..2, :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.txt"] == ["#{OUTPUT}/obama_arts_2.txt"]
  end

  def test_password_protected
    assert_raises(ExtractionFailed) do
      DocSplit.extract_text('test/fixtures/completely_encrypted.pdf')
    end
  end

end
