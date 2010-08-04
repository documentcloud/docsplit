module Docsplit

  class TextExtractor

    def extract(pdfs, opts)
      extract_options opts
      FileUtils.mkdir_p @output unless File.exists?(@output)
      [pdfs].flatten.each do |pdf|
        if @pages
          pages = (@pages == 'all') ? 1..Docsplit.extract_length(pdf) : @pages
          pages.each {|page| extract_page(pdf, page) }
        else
          extract_full(pdf)
        end
      end
    end


    private

    def extract_full(pdf)
      pdf_name = File.basename(pdf, File.extname(pdf))
      text_path = File.join(@output, "#{pdf_name}.txt")
      cmd = "pdftotext -enc UTF-8 #{pdf} #{text_path} 2>&1"
      result = `#{cmd}`.chomp
      raise ExtractionFailed, result if $? != 0
    end

    def extract_page(pdf, page)
      pdf_name = File.basename(pdf, File.extname(pdf))
      text_path = File.join(@output, "#{pdf_name}_#{page}.txt")
      cmd = "pdftotext -enc UTF-8 -f #{page} -l #{page} #{pdf} #{text_path} 2>&1"
      result = `#{cmd}`.chomp
      raise ExtractionFailed, result if $? != 0
    end

    def extract_options(options)
      @output  = options[:output] || '.'
      @pages   = options[:pages]
    end

  end

end