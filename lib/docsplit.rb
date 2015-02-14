require 'tmpdir'
require 'fileutils'
require 'shellwords'

# The Docsplit module delegates to the Java PDF extractors.
module Docsplit

  VERSION       = '0.8.0' # Keep in sync with gemspec.

  ESCAPE        = lambda {|x| Shellwords.shellescape(x) }

  ROOT          = File.expand_path(File.dirname(__FILE__) + '/..')
  ESCAPED_ROOT  = ESCAPE[ROOT]

  METADATA_KEYS = [:author, :date, :creator, :keywords, :producer, :subject, :title, :length]
  
  GM_FORMATS    = ["image/gif", "image/jpeg", "image/png", "image/x-ms-bmp", "image/svg+xml", "image/tiff", "image/x-portable-bitmap", "application/postscript", "image/x-portable-pixmap"]

  DEPENDENCIES  = {:java => false, :gm => false, :pdftotext => false, :pdftk => false, :pdftailor => false, :tesseract => false, :osd => false}

  # Check for all dependencies, and note their absence.
  dirs = ENV['PATH'].split(File::PATH_SEPARATOR)
  DEPENDENCIES.each_key do |dep|
    dirs.each do |dir|
      if File.executable?(File.join(dir, dep.to_s))
        DEPENDENCIES[dep] = true
        break
      end
    end
  end

  # if tesseract is found check for the osd plugin so that we can do orientation independent OCR.
  if DEPENDENCIES[:tesseract]
    # osd will be listed in tesseract --listlangs
    val = %x[ #{'tesseract --list-langs'} 2>&1 >/dev/null ]
    DEPENDENCIES[:osd] = true if val =~ /\bosd\b/
  end

    # Raise an ExtractionFailed exception when the PDF is encrypted, or otherwise
  # broke.
  class ExtractionFailed < StandardError; end

  # Use the ExtractPages Java class to burst a PDF into single pages.
  def self.extract_pages(pdfs, opts={})
    pdfs = ensure_pdfs(pdfs)
    PageExtractor.new.extract(pdfs, opts)
  end

  # Use the ExtractText Java class to write out all embedded text.
  def self.extract_text(pdfs, opts={})
    pdfs = ensure_pdfs(pdfs)
    TextExtractor.new.extract(pdfs, opts)
  end

  # Use the ExtractImages Java class to rasterize a PDF into each page's image.
  def self.extract_images(pdfs, opts={})
    pdfs = ensure_pdfs(pdfs)
    opts[:pages] = normalize_value(opts[:pages]) if opts[:pages]
    PDFShaverExtractor.new.extract(pdfs, opts)
  end

  # Use JODCConverter to extract the documents as PDFs.
  # If the document is in an image format, use GraphicsMagick to extract the PDF.
  def self.extract_pdf(docs, opts={})
    PdfExtractor.new.extract(docs, opts)
  end

  # Define custom methods for each of the metadata keys that we support.
  # Use the ExtractInfo Java class to print out a single bit of metadata.
  METADATA_KEYS.each do |key|
    instance_eval <<-EOS
      def self.extract_#{key}(pdfs, opts={})
        pdfs = ensure_pdfs(pdfs)
        InfoExtractor.new.extract(:#{key}, pdfs, opts)
      end
    EOS
  end
  
  def self.extract_info(pdfs, opts={})
    pdfs = ensure_pdfs(pdfs)
    InfoExtractor.new.extract_all(pdfs, opts)
  end

  # Utility method to clean OCR'd text with garbage characters.
  def self.clean_text(text)
    TextCleaner.new.clean(text)
  end

  private

  # Normalize a value in an options hash for the command line.
  # Ranges look like: 1-10, Arrays like: 1,2,3.
  def self.normalize_value(value)
    case value
    when Range then value.to_a.join(',')
    when Array then value.map! {|v| v.is_a?(Range) ? normalize_value(v) : v }.join(',')
    else            value.to_s
    end
  end

end

require "#{Docsplit::ROOT}/lib/docsplit/image_extractor"
require "#{Docsplit::ROOT}/lib/docsplit/transparent_pdfs"
require "#{Docsplit::ROOT}/lib/docsplit/text_extractor"
require "#{Docsplit::ROOT}/lib/docsplit/page_extractor"
require "#{Docsplit::ROOT}/lib/docsplit/pdf_extractor"
require "#{Docsplit::ROOT}/lib/docsplit/info_extractor"
require "#{Docsplit::ROOT}/lib/docsplit/text_cleaner"
