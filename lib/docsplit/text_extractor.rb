require 'nokogiri'

module Docsplit

  # Delegates to **pdftotext** and **tesseract** in order to extract text from
  # PDF documents. The `--ocr` and `--no-ocr` flags can be used to force or
  # forbid OCR extraction, but by default the heuristic works like this:
  #
  #  * Check for the presence of fonts in the PDF. If no fonts are detected,
  #    OCR is used automatically.
  #  * Extract the text of each page with **pdftotext**, if the page has less
  #    than 100 bytes of text (a scanned image page, or a page that just
  #    contains a filename and a page number), then add it to the list of
  #    `@pages_to_ocr`.
  #  * Re-OCR each page in the `@pages_to_ocr` list at the end.
  #
  class TextExtractor

    NO_TEXT_DETECTED = /---------\n\Z/

    OCR_FLAGS   = '-density 400x400 -colorspace GRAY'
    MEMORY_ARGS = '-limit memory 256MiB -limit map 512MiB'

    MIN_TEXT_PER_PAGE = 100 # in bytes

    HOCR_SECTIONS = [ [ '.ocr_par',   "\n\n" ],
                      [ '.ocr_line',  "\n"   ],
                      [ '.ocrx_word', " "    ] ]

    def initialize
      @pages_to_ocr = []
    end

    # Extract text from a list of PDFs.
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
    end

    # Does a PDF have any text embedded?
    def contains_text?(pdf)
      fonts = `pdffonts #{ESCAPE[pdf]} 2>&1`
      !fonts.match(NO_TEXT_DETECTED)
    end

    # Extract a page range worth of text from a PDF, directly.
    def extract_from_pdf(pdf, pages)
      return extract_full(pdf) unless pages
      pages.each {|page| extract_page(pdf, page) }
    end

    # Extract a page range worth of text from a PDF via OCR.
    def extract_from_ocr(pdf, pages)
      tempdir = Dir.mktmpdir
      base_path = File.join(@output, @pdf_name)
      escaped_pdf = ESCAPE[pdf]
      if pages
        pages.each do |page|
          tiff = "#{tempdir}/#{@pdf_name}_#{page}.tif"
          escaped_tiff = ESCAPE[tiff]
          file = "#{base_path}_#{page}"
          run "MAGICK_TMPDIR=#{tempdir} OMP_NUM_THREADS=2 gm convert -despeckle +adjoin #{MEMORY_ARGS} #{OCR_FLAGS} #{escaped_pdf}[#{page - 1}] #{escaped_tiff} 2>&1"
          run "tesseract #{escaped_tiff} #{ESCAPE[file]} -l #{@language} #{@config} 2>&1"
          run "cp #{escaped_tiff} #{base_path}_#{page}.tif" if @gen_hocr
          clean_ocr(file) if @clean_ocr
          generate_text_and_annotate(file) if @gen_hocr
          FileUtils.remove_entry_secure tiff
        end
      else
        tiff = "#{tempdir}/#{@pdf_name}.tif"
        escaped_tiff = ESCAPE[tiff]
        run "MAGICK_TMPDIR=#{tempdir} OMP_NUM_THREADS=2 gm convert -despeckle #{MEMORY_ARGS} #{OCR_FLAGS} #{escaped_pdf} #{escaped_tiff} 2>&1"
        run "tesseract #{escaped_tiff} #{base_path} -l #{@language} #{@config} 2>&1"
        run "cp #{escaped_tiff} #{base_path}.tif" if @gen_hocr
        clean_ocr(base_path) if @clean_ocr
        generate_text_and_annotate(base_path) if @gen_hocr
      end
    ensure
      FileUtils.remove_entry_secure tempdir if File.exists?(tempdir)
    end


    private

    def clean_ocr(basename)
      ext = @gen_hocr ? "html" : "txt"
      File.open(basename + ".#{ext}", 'r+') do |f|
        content = f.read
        f.truncate(0)
        f.rewind
        meth = @gen_hocr ? "hocr" : "text"
        f.write(Docsplit.send("clean_#{meth}".to_sym, content))
      end
    end

    # When generating hOCR output, tesseract doesn't generate text output.
    # This method will generate the text output, and also add the corresponding
    # character position of the words back into the hOCR file as HTML data
    # attributes.
    def generate_text_and_annotate(basename)
      File.open(basename + '.txt', 'w') do |output|
        File.open(basename + '.html', 'r+') do |input|
          xml = Nokogiri::XML(input.read)
          generate_text_position(xml) do |text, pos, elt|
            # Write the output text file
            output.write(text)

            # Annotate the hOCR element we are given
            if elt
              elt['data-start'] = pos
              elt['data-stop' ] = pos + text.size
            end
          end
          input.truncate(0)
          input.rewind
          input.write(xml.to_xml)
        end
      end
    end

    def generate_text_position(root, index=0, pos=0, &block)
      raise RuntimeError, "bad section list" if index >= HOCR_SECTIONS.size
      # Select the sections we want at this level
      sections = root.css(HOCR_SECTIONS[index][0])
      sections.each do |section|
        if index < HOCR_SECTIONS.size - 1
          # It is not the base section, so recurse.
          pos = generate_text_position(section, index + 1, pos, &block)
        else
          # It is the base section (a word), so emit the
          # text and the xml element so the caller can
          # annotate.
          block.call(section.text, pos, section) if block
          pos += section.text.size
        end

        # We 'join' the sections with the specified separator.
        # Emit the section join text, but without the xml
        # element, since this is just generate text.
        if section != sections.last
          block.call(HOCR_SECTIONS[index][1], pos, nil) if block
          pos += HOCR_SECTIONS[index][1].size
        end
      end
      pos
    end

    # Run an external process and raise an exception if it fails.
    def run(command)
      result = `#{command}`
      raise ExtractionFailed, result if $? != 0
      result
    end

    # Extract the full contents of a pdf as a single file, directly.
    def extract_full(pdf)
      text_path = File.join(@output, "#{@pdf_name}.txt")
      run "pdftotext -enc UTF-8 #{ESCAPE[pdf]} #{ESCAPE[text_path]} 2>&1"
    end

    # Extract the contents of a single page of text, directly, adding it to
    # the `@pages_to_ocr` list if the text length is inadequate.
    def extract_page(pdf, page)
      text_path = File.join(@output, "#{@pdf_name}_#{page}.txt")
      run "pdftotext -enc UTF-8 -f #{page} -l #{page} #{ESCAPE[pdf]} #{ESCAPE[text_path]} 2>&1"
      unless @forbid_ocr
        @pages_to_ocr.push(page) if File.read(text_path).length < MIN_TEXT_PER_PAGE
      end
    end

    def extract_options(options)
      @output     = options[:output] || '.'
      @pages      = options[:pages]
      @force_ocr  = options[:ocr] == true
      @forbid_ocr = options[:ocr] == false
      @clean_ocr  = !(options[:clean] == false)
      @language   = options[:language] || 'eng'
      @gen_hocr   = check_tesseract_config(options[:config])
      @config     = options[:config] || ''
    end

    def check_tesseract_config(config)
      return false unless config
      hocr_configs = File.open(config, 'r').grep(/tessedit_create_hocr/)
      if hocr_configs.size > 0
        return hocr_configs.last.split[1] != "0"
      end
      false
    end

  end

end
