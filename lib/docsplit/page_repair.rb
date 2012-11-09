module Docsplit

  # Delegates to **pdftk** in order to repair PDF document(s).
  class PageRepair

    # Open a list of pdf files with pdftk then save them.
    # Helps to "repair" some pdf files that crash pdftk on extract
    def repair(pdfs, opts)
      repair_options opts
      [pdfs].flatten.each do |pdf|
        pdf_name = File.basename(pdf, File.extname(pdf))
        page_path = File.join(@output, "#{pdf_name}_repaired.pdf")
        FileUtils.mkdir_p @output unless File.exists?(@output)
        cmd = "pdftk #{ESCAPE[pdf]} output #{ESCAPE[page_path]} 2>&1"
        result = `#{cmd}`.chomp
        FileUtils.rm('doc_data.txt') if File.exists?('doc_data.txt')
        raise RepairFailed, result if $? != 0
        result
      end
    end

    private

    def repair_options(options)
      @output = options[:output] || '.'
    end

  end

end