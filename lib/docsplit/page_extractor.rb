module Docsplit

  # Delegates to **pdftk** in order to create bursted single pages from
  # a PDF document.
  class PageExtractor

    # Burst a list of pdfs into single pages, as `pdfname_pagenumber.pdf`.
    def extract(pdfs, opts)
      extract_options opts
      [pdfs].flatten.each do |pdf|
        pdf_name = File.basename(pdf, File.extname(pdf))
        page_format = page_number_format(pdf)
        page_path = File.join(@output, "#{pdf_name}_#{page_format}.pdf")
        FileUtils.mkdir_p @output unless File.exists?(@output)
        
        cmd = if DEPENDENCIES[:pdftailor] # prefer pdftailor, but keep pdftk for backwards compatability
          "pdftailor unstitch --output #{ESCAPE[page_path]} #{ESCAPE[pdf]} 2>&1"
        else
          "pdftk #{ESCAPE[pdf]} burst output #{ESCAPE[page_path]} 2>&1"
        end
        result = `#{cmd}`.chomp
        FileUtils.rm('doc_data.txt') if File.exists?('doc_data.txt')
        raise ExtractionFailed, result if $? != 0
        result
      end
    end


    private

    def extract_options(options)
      @output = options[:output] || '.'
      @zeros  = !!options[:leading_zeros]
    end

    # Generate the appropriate page number format. 
    def page_number_format(pdf)
      digits = Docsplit.extract_length(pdf).to_s.length
      # PDFTailor doesn't support printf-style format in the output, yet
      (!DEPENDENCIES[:pdftailor] && @zeros) ? "%0#{digits}d" : "%d"
    end

  end

end