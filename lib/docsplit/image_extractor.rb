module DocSplit

  # Delegates to GraphicsMagick in order to convert PDF documents into
  # nicely sized images.
  class ImageExtractor

    DENSITY_ARG = "-density 150"
    DEFAULT_FORMAT = :png

    # Extract a list of PDFs as rasterized page images, according to the
    # configuration in options.
    def extract(pdfs, options)
      @pdfs = [pdfs].flatten
      extract_options(options)
      @pdfs.each {|p| @sizes.each {|s| @formats.each {|f| convert(p, s, f) }}}
    end

    # Convert a single PDF into page images at the specified size and format.
    def convert(pdf, size, format)
      basename  = File.basename(pdf, File.extname(pdf))
      subfolder = @sizes.length > 1 ? size.to_s : ''
      directory = File.join(@output, subfolder)
      FileUtils.mkdir_p(directory) unless File.exists?(directory)
      out_file  = File.join(directory, "#{basename}_%d.#{format}")
      cmd = "gm convert #{DENSITY_ARG} #{resize_arg(size)} #{quality_arg(format)} \"#{pdf}#{pages_arg}\" \"#{out_file}\" 2>&1"
      result = `#{cmd}`.chomp
      raise ExtractionFailed, result if $? != 0
      renumber_images(out_file, format)
    end


    private

    # Extract the relevant GraphicsMagick options from the options hash.
    def extract_options(options)
      @output  = options[:output]  || '.'
      @pages   = options[:pages]
      @formats = [options[:format] || DEFAULT_FORMAT].flatten
      @sizes   = [options[:size]].flatten.compact
      @sizes   = [nil] if @sizes.empty?
    end

    # Generate the resize argument.
    def resize_arg(size)
      size.nil? ? '' : "-resize #{size}"
    end

    # Generate the appropriate quality argument for the image format.
    def quality_arg(format)
      case format.to_s
      when /jpe?g/ then "-quality 85"
      when /png/   then "-quality 100"
      else ""
      end
    end

    # Generate the requested page index into the document.
    def pages_arg
      return '' if @pages.nil?
      pages = @pages.gsub(/\d+/) {|digits| (digits.to_i - 1).to_s }
      "[#{pages}]"
    end

    # Generate the expanded list of requested page numbers.
    def page_list
      @pages.split(',').map { |range|
        if range.include?('-')
          range = range.split('-')
          Range.new(range.first, range.last).to_a.map {|n| n.to_i }
        else
          range.to_i
        end
      }.flatten.sort
    end

    # When GraphicsMagick is through, it will have generated a number of
    # incrementing page images, starting at 0. Renumber them with their correct
    # page numbers.
    def renumber_images(template, format)
      suffixer = /_(\d+)\.#{format}\Z/
      images = Dir[template.sub('%d', '*')].map do |path|
        index = path[suffixer, 1].to_i
        {:path => path, :index => index, :page_number => index + 1}
      end
      numbers = @pages ? page_list.reverse : nil
      images.sort_by {|i| -i[:page_number] }.each_with_index do |image, i|
        number = numbers ? numbers[i] : image[:page_number]
        FileUtils.mv(image[:path], image[:path].sub(suffixer, "_#{number}.#{format}"))
      end
    end

  end

end
