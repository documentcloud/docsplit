Gem::Specification.new do |s|
  s.name      = 'docsplit'
  s.version   = '0.1.0'         # Keep version in sync with jammit.rb
  s.date      = '2009-12-07'

  s.homepage    = "http://documentcloud.github.com/docsplit/"
  s.summary     = "Break Apart Documents into Images, Text, Pages and PDFs"
  s.description = <<-EOS
    Docsplit is a command-line utility and Ruby library for splitting apart
    documents into their component parts: searchable UTF-8 plain text, page
    images or thumbnails in any format, PDFs, single pages, and document
    metadata (title, author, number of pages...)
  EOS

  s.authors           = ['Jeremy Ashkenas']
  s.email             = 'jeremy@documentcloud.org'
  s.rubyforge_project = 'docsplit'

  s.require_paths     = ['lib']
  s.executables       = ['docsplit']

  s.has_rdoc          = false
  s.extra_rdoc_files  = ['README']
  s.rdoc_options      << '--title'    << 'PDF Pieces' <<
                         '--exclude'  << 'test' <<
                         '--main'     << 'README' <<
                         '--all'

  s.files = Dir['build/**/*', 'lib/**/*', 'bin/*', 'vendor/**/*', 'docsplit.gemspec', 'LICENSE', 'README']
end