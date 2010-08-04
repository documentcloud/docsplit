module Docsplit

  # Delegates to **pdftk** in order to create bursted single pages from
  # a PDF document.
  class PageExtractor

    def extract(pdfs, opts)
      extract_options opts
      [pdfs].flatten.each do |pdf|
        pdf_name = File.basename(pdf, File.extname(pdf))
        page_path = File.join(@output, "#{pdf_name}_%d.pdf")
        FileUtils.mkdir_p @output unless File.exists?(@output)
        cmd = "pdftk #{pdf} burst output #{page_path} 2>&1"
        result = `#{cmd}`.chomp
        FileUtils.rm('doc_data.txt') if File.exists?('doc_data.txt')
        raise ExtractionFailed, result if $? != 0
        result
      end
    end


    private

    def extract_options(options)
      @output  = options[:output] || '.'
    end

  end

end