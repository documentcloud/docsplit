module Docsplit

  class TextExtractor

    NO_TEXT_DETECTED = /---------\n\Z/

    OCR_FLAGS = '-density 200x200 -colorspace GRAY'

    MIN_TEXT_PER_PAGE = 100 # bytes

    def initialize
      @tiffs_generated = false
      @pages_to_ocr    = []
    end

    def extract(pdfs, opts)
      extract_options opts
      FileUtils.mkdir_p @output unless File.exists?(@output)
      [pdfs].flatten.each do |pdf|
        @pdf_name = File.basename(pdf, File.extname(pdf))
        pages = (@pages == 'all') ? 1..Docsplit.extract_length(pdf) : @pages
        if @force_ocr || (!@forbid_ocr && !contains_text?(pdf))
          extract_from_ocr(pdf, pages)
        else
          extract_from_pdf(pdf, pages)
          if !@forbid_ocr && DEPENDENCIES[:tesseract] && !@pages_to_ocr.empty?
            extract_from_ocr(pdf, @pages_to_ocr)
          end
        end
      end
      FileUtils.remove_entry_secure @tempdir if @tempdir
    end

    def contains_text?(pdf)
      fonts = `pdffonts #{pdf} 2>&1`
      !fonts.match(NO_TEXT_DETECTED)
    end

    def extract_from_pdf(pdf, pages)
      return extract_full(pdf) unless pages
      pages.each {|page| extract_page(pdf, page) }
    end

    def extract_from_ocr(pdf, pages)
      @tempdir  ||= Dir.mktmpdir
      base_path = File.join(@output, @pdf_name)
      if pages
        run "gm convert +adjoin #{OCR_FLAGS} #{pdf} #{@tempdir}/#{@pdf_name}_%d.tif 2>&1" unless @tiffs_generated
        @tiffs_generated = true
        pages.each do |page|
          run "tesseract #{@tempdir}/#{@pdf_name}_#{page - 1}.tif #{base_path}_#{page} 2>&1"
        end
      else
        tiff = "#{@tempdir}/#{@pdf_name}.tif"
        run "gm convert #{OCR_FLAGS} #{pdf} #{tiff} 2>&1"
        run "tesseract #{tiff} #{base_path} -l eng 2>&1"
      end
    end


    private

    def run(command)
      result = `#{command}`
      raise ExtractionFailed, result if $? != 0
      result
    end

    def extract_full(pdf)
      text_path = File.join(@output, "#{@pdf_name}.txt")
      run "pdftotext -enc UTF-8 #{pdf} #{text_path} 2>&1"
    end

    def extract_page(pdf, page)
      text_path = File.join(@output, "#{@pdf_name}_#{page}.txt")
      run "pdftotext -enc UTF-8 -f #{page} -l #{page} #{pdf} #{text_path} 2>&1"
      unless @forbid_ocr
        @pages_to_ocr.push(page) if File.read(text_path).length < MIN_TEXT_PER_PAGE
      end
    end

    def extract_options(options)
      @output     = options[:output] || '.'
      @pages      = options[:pages]
      @force_ocr  = options[:ocr] == true
      @forbid_ocr = options[:ocr] == false
    end

  end

end