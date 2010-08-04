module Docsplit

  class TextExtractor

    def extract(pdfs, opts)
      extract_options opts
      [pdfs].flatten.each do |pdf|
        pdf_name = File.basename(pdf, File.extname(pdf))
        text_path = File.join(@output, "#{pdf_name}.txt")
        FileUtils.mkdir_p @output unless File.exists?(@output)
        if @pages
          pages = (@pages == 'all') ? 1..Docsplit.extract_length(pdf) : @pages
          pages.each do |page|
            extract_page pdf, page, pdf_name
          end
        else
          cmd = "pdftotext -enc UTF-8 #{pdf} #{text_path} 2>&1"
          result = `#{cmd}`.chomp
          raise ExtractionFailed, result if $? != 0
        end
      end
    end

    def extract_page(pdf, page, pdf_name)
      text_path = File.join(@output, "#{pdf_name}_#{page}.txt")
      cmd = "pdftotext -enc UTF-8 -f #{page} -l #{page} #{pdf} #{text_path} 2>&1"
      result = `#{cmd}`.chomp
      raise ExtractionFailed, result if $? != 0
      result
    end

    private

    def extract_options(options)
      @output  = options[:output] || '.'
      @pages   = options[:pages]
    end

  end

end