module Docsplit

  # Delegates to GraphicsMagick in order to convert PDF documents into
  # nicely sized images.
  class ImageExtractor

    DENSITY_ARG       = "-density 100"
    MEMORY_ARGS       = "-limit memory 256MiB -limit map 512MiB"
    GHOSTSCRIPT_ARGS  = "-q -dBATCH -dMaxBitmap=50000000 -dNOPAUSE -sDEVICE=tiff24nc -dTextAlphaBits=4 -dGraphicsAlphaBits=4 -r100x100"
    DEFAULT_FORMAT    = :png
    CHUNK_SIZE        = 10

    # Extract a list of PDFs as rasterized page images, according to the
    # configuration in options.
    def extract(pdfs, options)
      @pdfs = [pdfs].flatten
      extract_options(options)
      @pdfs.each do |pdf|
        previous = nil
        @sizes.each_with_index do |size, i|
          @formats.each {|format| convert(pdf, size, format, previous) }
          previous = size if @rolling
        end
      end
    end

    # Convert a single PDF into page images at the specified size and format.
    def convert(pdf, size, format, previous=nil)
      tempdir   = Dir.mktmpdir
      basename  = File.basename(pdf, File.extname(pdf))
      directory = directory_for(size)
      pages     = @pages || '1-' + Docsplit.extract_length(pdf).to_s
      FileUtils.mkdir_p(directory) unless File.exists?(directory)
      tiff_file = File.join(tempdir, "#{basename}.tif")
      common    = "#{MEMORY_ARGS} #{DENSITY_ARG} #{resize_arg(size)} #{quality_arg(format)}"
      if previous
        FileUtils.cp(Dir[directory_for(previous) + '/*'], directory)
        cmd = "MAGICK_TMPDIR=#{tempdir} OMP_NUM_THREADS=2 gm mogrify #{common} -unsharp 0x0.5+0.75 \"#{directory}/*.#{format}\" 2>&1"
      else
        cmd = "gs #{GHOSTSCRIPT_ARGS} -sOutputFile=#{tiff_file} -- #{pdf}"
        page_list(pages, CHUNK_SIZE).each_with_index do |nums, chunk|
          out_file = File.join(directory, "#{basename}_chunk#{chunk}_%05d.#{format}")
          cmd += " && MAGICK_TMPDIR=#{tempdir} OMP_NUM_THREADS=2 gm convert +adjoin #{common} \"#{tiff_file}#{pages_arg(nums)}\" \"#{out_file}\" 2>&1"
        end
      end
      result = `#{cmd}`.chomp
      raise ExtractionFailed, result if $? != 0
      renumber_images(pages, File.join(directory, basename + '*.' + format), format) unless previous
      FileUtils.remove_entry_secure tempdir if File.exists?(tempdir)
    end


    private

    # Extract the relevant GraphicsMagick options from the options hash.
    def extract_options(options)
      @output  = options[:output]  || '.'
      @pages   = options[:pages]
      @formats = [options[:format] || DEFAULT_FORMAT].flatten
      @sizes   = [options[:size]].flatten.compact
      @sizes   = [nil] if @sizes.empty?
      @rolling = !!options[:rolling]
    end

    # If there's only one size requested, generate the images directly into
    # the output directory. Multiple sizes each get a directory of their own.
    def directory_for(size)
      path = @sizes.length == 1 ? @output : File.join(@output, size)
      File.expand_path(path)
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
    def pages_arg(numbers)
      '[' + numbers.map {|num| num - 1 }.join(',') + ']'
    end

    # Generate the expanded list of requested page numbers.
    def page_list(pages, chunk_count=nil)
      list = pages.split(',').map { |range|
        if range.include?('-')
          range = range.split('-')
          Range.new(range.first.to_i, range.last.to_i).to_a.map {|n| n.to_i }
        else
          range.to_i
        end
      }.flatten.sort
      return list unless chunk_count
      chunks = []
      list.each_with_index do |num, i|
        chunks << [] if i % chunk_count == 0
        chunks.last << num
      end
      chunks
    end

    # When GraphicsMagick is through, it will have generated a number of
    # incrementing page images, starting at 0. Renumber them with their correct
    # page numbers.
    def renumber_images(pages, glob, format)
      suffixer = /_chunk(\d+)_0+(\d+)\.#{format}\Z/
      images = Dir[glob].map do |path|
        chunk = path[suffixer, 1].to_i
        index = chunk * CHUNK_SIZE + path[suffixer, 2].to_i
        {:path => path, :index => index, :page_number => index + 1}
      end
      numbers = page_list(pages).reverse
      images.sort_by {|i| -i[:page_number] }.each_with_index do |image, i|
        number = numbers ? numbers[i] : image[:page_number]
        FileUtils.mv(image[:path], image[:path].sub(suffixer, "_#{number}.#{format}"))
      end
    end

  end

end
