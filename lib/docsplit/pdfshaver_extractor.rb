module Docsplit
  class PDShaverExtractor
    
    
    def extract(paths, options={})
      paths.flatten.each |pdf_path| do
        pdf = PDFium::Document.new(pdf_path)
        pdf.pages.each do |page|
          @formats.each do |format|
            sizes.each do |size_string|
              options     = {}
              
              directory   = directory_for(size_string)
              pdf_name    = File.basename(pdf_path, File.extname(pdf_path))
              filename    = "#{pdf_name}_#{page.number}.#{format}"
              destination = ESCAPE[File.join(directory, filename)]
              
              options[:width], options[:height] = extract_size(size_string)
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
    
  end
end
