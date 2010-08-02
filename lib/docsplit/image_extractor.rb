module Docsplit

  # Delegates to GraphicsMagick in order to convert PDF documents into
  # nicely sized images.
  class ImageExtractor

    DENSITY_ARG     = "-density 150"
    MEMORY_ARGS     = "-limit memory 128MiB -limit map 256MiB"
    DEFAULT_FORMAT  = :png

    # Extract a list of PDFs as rasterized page images, according to the
    # configuration in options.
    def extract(pdfs, options)
      @pdfs = [pdfs].flatten
      extract_options(options)
      @pdfs.each do |pdf|
        previous = nil
        @sizes.each_with_index do |size, i|
          @formats.each {|format| convert(pdf, size, format, previous) }
          previous = size if @resize
        end
      end
    end

    # Convert a single PDF into page images at the specified size and format.
    def convert(pdf, size, format, previous=nil)
      basename  = File.basename(pdf, File.extname(pdf))
      directory = directory_for(size)
      FileUtils.mkdir_p(directory) unless File.exists?(directory)
      out_file  = File.join(directory, "#{basename}_%05d.#{format}")
      common    = "#{MEMORY_ARGS} #{DENSITY_ARG} #{resize_arg(size)} #{quality_arg(format)}"
      if previous
        FileUtils.cp(Dir[directory_for(previous) + '/*'], directory)
        cmd = "OMP_NUM_THREADS=2 gm mogrify #{common} -unsharp 0x0.5 \"#{directory}/*.#{format}\" 2>&1"
      else
        cmd = "OMP_NUM_THREADS=2 gm convert +adjoin #{common} \"#{pdf}#{pages_arg}\" \"#{out_file}\" 2>&1"
      end
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
      @resize  = !!options[:resize]
    end

    def directory_for(size)
      return @output if @sizes.length == 1
      File.join(@output, size)
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
          Range.new(range.first.to_i, range.last.to_i).to_a.map {|n| n.to_i }
        else
          range.to_i
        end
      }.flatten.sort
    end

    # When GraphicsMagick is through, it will have generated a number of
    # incrementing page images, starting at 0. Renumber them with their correct
    # page numbers.
    def renumber_images(template, format)
      suffixer = /_0+(\d+)\.#{format}\Z/
      images = Dir[template.sub('%05d', '0*')].map do |path|
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
