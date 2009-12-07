Gem::Specification.new do |s|
  s.name      = 'docsplit'
  s.version   = '0.1.0'         # Keep version in sync with jammit.rb
  s.date      = '2009-11-29'

  s.homepage    = "http://documentcloud.github.com/docsplit/"
  s.summary     = "TBD"
  s.description = <<-EOS
    TBD
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

  s.files = Dir['build/**/*', 'lib/**/*', 'bin/*', 'vendor/**/*', 'docsplit.gemspec', 'LICENSE', 'README']
end