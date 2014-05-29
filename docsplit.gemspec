lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'docsplit/version'

Gem::Specification.new do |s|
  s.name      = 'docsplit'
  s.version   = Docsplit::VERSION

  s.homepage    = 'http://documentcloud.github.io/docsplit/'
  s.summary     = "Break Apart Documents into Images, Text, Pages and PDFs"
  s.description = <<-EOS
    Docsplit is a command-line utility and Ruby library for splitting apart
    documents into their component parts: searchable UTF-8 plain text, page
    images or thumbnails in any format, PDFs, single pages, and document
    metadata (title, author, number of pages...)
  EOS

  s.authors           = ['Jeremy Ashkenas', 'Samuel Clay', 'Ted Han']
  s.email             = 'opensource@documentcloud.org'
  s.rubyforge_project = 'docsplit'
  s.license           = 'MIT'

  s.require_paths     = ['lib']
  s.executables       = ['docsplit']

  s.files = Dir['build/**/*', 'lib/**/*', 'bin/*', 'vendor/**/*',
                'docsplit.gemspec', 'LICENSE', 'README']

  s.add_development_dependency 'bundler', '~> 1.5'
  s.add_development_dependency 'rake'

  s.requirements << 'GraphicsMagick'
  s.requirements << 'Poppler'
  s.requirements << 'Ghostscript (optional)'
  s.requirements << 'Tesseract (optional)'
  s.requirements << 'pdftk (optional)'
  s.requirements << 'LibreOffice (optional)'
end
