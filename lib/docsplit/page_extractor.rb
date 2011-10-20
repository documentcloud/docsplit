module Docsplit

  # Delegates to **pdftk** in order to create bursted single pages from
  # a PDF document.
  class PageExtractor

    # Burst a list of pdfs into single pages, as `pdfname_pagenumber.pdf`.
    def extract(pdfs, opts)
      extract_options opts
      [pdfs].flatten.each do |pdf|
        pdf_name = File.basename(pdf, File.extname(pdf))
        page_path = File.join(@output, "#{pdf_name}_%d.pdf")
        FileUtils.mkdir_p @output unless File.exists?(@output)
        cmd = "pdftk #{ESCAPE[pdf]} burst output #{ESCAPE[page_path]} 2>&1"
        begin
            result = `#{cmd}`.chomp
            raise EncryptedPDF, pdf if result.include? "OWNER PASSWORD REQUIRED"
            raise ExtractionFailed, result if $? != 0
        # Catch when PDF is encrypted
        rescue EncryptedPDF => pdf
           # And if qpdf is installed ...
           if DEPENDENCIES[:qpdf] and not opts[:retry]
              # Decrypt it
              temppath = Docsplit.decrypt_pdf(pdf)
              # Signal a retry
              opts[:retry] = true
              # Try again, recursively
              extract([temppath], opts)
              # Forget all about retry
              opts[:retry] = false
              # Delete temp path
              FileUtils.rm(temppath)
              # Move on to the next guy in the loop
              next
           end
        end
        FileUtils.rm('doc_data.txt') if File.exists?('doc_data.txt')
        result
      end
    end

    private

    def extract_options(options)
      @output = options[:output] || '.'
    end

  end

end
