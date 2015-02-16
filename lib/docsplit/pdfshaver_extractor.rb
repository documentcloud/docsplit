require 'pdfshaver'
module Docsplit
  class PDFShaverExtractor
    
    MEMORY_ARGS     = "-limit memory 256MiB -limit map 512MiB"
    DEFAULT_FORMAT  = :png
    DEFAULT_DENSITY = '150'
    
    def extract(paths, options={})
      extract_options(options)
      paths.flatten.each do |pdf_path|
        begin
          pdf = PDFShaver::Document.new(pdf_path)
        rescue ArgumentError => e
          raise ExtractionFailed
        end
        pdf.pages.each do |page|
          @formats.each do |format|
            @sizes.each do |size_string|
              options     = {}
              
              directory   = directory_for(size_string)
              pdf_name    = File.basename(pdf_path, File.extname(pdf_path))
              filename    = "#{pdf_name}_#{page.number}.#{format}"
              destination = File.join(directory, filename)
              FileUtils.mkdir_p ESCAPE[directory]
              
              options = options.merge extract_size(size_string)
              page.render(destination, options)
            end
          end
        end
      end
    end
    
    private
    def extract_size(size_string)
      height = nil
      width  = nil
      
      {:height => height, :width => width }
    end
    
    # If there's only one size requested, generate the images directly into
    # the output directory. Multiple sizes each get a directory of their own.
    def directory_for(size)
      path = @sizes.length == 1 ? @output : File.join(@output, size)
      File.expand_path(path)
    end
    
    def extract_options(options)
      @output  = options[:output]  || '.'
      @pages   = options[:pages]
      @density = options[:density] || DEFAULT_DENSITY
      @formats = [options[:format] || DEFAULT_FORMAT].flatten
      @sizes   = [options[:size]].flatten.compact
      @sizes   = [nil] if @sizes.empty?
      @rolling = !!options[:rolling]
    end
  end
end
