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
        pdf.pages(extract_page_list(@pages)).each do |page|
          @formats.each do |format|
            @sizes.each do |size_string|
              directory   = directory_for(size_string)
              pdf_name    = File.basename(pdf_path, File.extname(pdf_path))
              filename    = "#{pdf_name}_#{page.number}.#{format}"
              destination = File.join(directory, filename)
              FileUtils.mkdir_p ESCAPE[directory]
              
              dimensions = page.extract_dimensions_from_gm_geometry_string(size_string)
              page.render(destination, dimensions)
            end
          end
        end
      end
    end
    
    private
    # If there's only one size requested, generate the images directly into
    # the output directory. Multiple sizes each get a directory of their own.
    def directory_for(size)
      path = @sizes.length == 1 ? @output : File.join(@output, size)
      File.expand_path(path)
    end
    
    # Generate the expanded list of requested page numbers.
    def extract_page_list(pages)
      return :all if pages.nil?
      pages.split(',').map { |range|
        if range.include?('-')
          range = range.split('-')
          Range.new(range.first.to_i, range.last.to_i).to_a.map {|n| n.to_i }
        else
          range.to_i
        end
      }.flatten.uniq.sort
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
