module Docsplit
  
  class TextExtractor
    
    PAGE_COUNT_MATCHER = /Pages:\s+(\d+?)\n/
    
    def extract(pdfs, opts)
      extract_options opts
      pdfs = [pdfs].flatten
      pdfs.each do |pdf|
        pdf_name = File.basename(pdf, File.extname(pdf))
        text_path = File.join(@output, "#{pdf_name}.txt")
        FileUtils.mkdir_p @output
      
        if @pages
          pages = (@pages == 'all') ? 1..get_pages(pdf) : @pages
          pages.each do |page| 
            extract_page pdf, page, pdf_name
          end
        else
          cmd = "pdftotext -enc UTF-8 #{pdf} #{text_path}"
          result = `#{cmd}`.chomp
          raise ExtractionFailed, result if $? != 0
        end
      end
    end
  
    def extract_page(pdf, page, pdf_name)
      text_path = File.join(@output, "#{pdf_name}_#{page}.txt")
      cmd = "pdftotext -enc UTF-8 -f #{page} -l #{page} #{pdf} #{text_path}"
      result = `#{cmd}`.chomp
      raise ExtractionFailed, result if $? != 0
      result
    end

    def get_pages(pdf_path)
      info = `pdfinfo #{pdf_path}`
      raise ExtractionFailed, result if $? != 0
      match = info.match(PAGE_COUNT_MATCHER)
      raise ExtractionFailed if match.nil?
      match[1].to_i
    end
    
    private
    
    def extract_options(options)
      @output  = options[:output] || '.'
      @pages   = options[:pages]
    end

  end
  
end