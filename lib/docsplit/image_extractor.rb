module Docsplit

  # Delegates to GraphicsMagick in order to convert PDF documents into
  # nicely sized images.
  class ImageExtractor

    MEMORY_ARGS     = "-limit memory 256MiB -limit map 512MiB"
    DEFAULT_FORMAT  = :png
    DEFAULT_DENSITY = '150'

    # Extract a list of PDFs as rasterized page images, according to the
    # configuration in options.
    def extract(pdfs, options)
      @pdfs = [pdfs].flatten
      extract_options(options)
      images = []
      @pdfs.each do |pdf|
        previous = nil
        @sizes.each_with_index do |size, i|
          images += @formats.map {|format| convert(pdf, size, format, previous) }
          previous = size if @rolling
        end
      end
      case @return_value
      when :images
        images.reject{|i| i.nil? or i.empty?}.flatten
      when :intermediates
        @pdfs
      else
        @pdfs
      end
    end

    # Convert a single PDF into page images at the specified size and format.
    # If `--rolling`, and we have a previous image at a larger size to work with,
    # we simply downsample that image, instead of re-rendering the entire PDF.
    # Now we generate one page at a time, a counterintuitive opimization
    # suggested by the GraphicsMagick list, that seems to work quite well.
    def convert(pdf, size, format, previous=nil)
      tempdir   = Dir.mktmpdir
      basename  = File.basename(pdf, File.extname(pdf))
      directory = directory_for(size)
      pages     = @pages || '1-' + Docsplit.extract_length(pdf).to_s
      escaped_pdf = ESCAPE[pdf]
      FileUtils.mkdir_p(directory) unless File.exists?(directory)
      common    = "#{MEMORY_ARGS} -density #{@density} #{resize_arg(size)} #{quality_arg(format)}"
      image_paths = []
      if previous
        FileUtils.cp(Dir[directory_for(previous) + '/*'], directory)
        result = `MAGICK_TMPDIR=#{tempdir} OMP_NUM_THREADS=2 gm mogrify #{common} -unsharp 0x0.5+0.75 \"#{directory}/*.#{format}\" 2>&1`.chomp
        raise ExtractionFailed, result if $? != 0
      else
        page_list(pages).each do |page|
          out_file  = ESCAPE[File.join(directory, "#{basename}_#{page}.#{format}")]
          image_paths << out_file
          cmd = "MAGICK_TMPDIR=#{tempdir} OMP_NUM_THREADS=2 gm convert +adjoin -define pdf:use-cropbox=true #{common} #{escaped_pdf}[#{page - 1}] #{out_file} 2>&1".chomp
          result = `#{cmd}`.chomp
          raise ExtractionFailed, result if $? != 0

        end
        return image_paths
      end
    ensure
      FileUtils.remove_entry_secure tempdir if File.exists?(tempdir)
    end


    private

    # Extract the relevant GraphicsMagick options from the options hash.
    def extract_options(options)
      @output  = options[:output]  || '.'
      @pages   = options[:pages]
      @density = options[:density] || DEFAULT_DENSITY
      @formats = [options[:format] || DEFAULT_FORMAT].flatten
      @sizes   = [options[:size]].flatten.compact
      @sizes   = [nil] if @sizes.empty?
      @rolling = !!options[:rolling]
      @return_value = options[:and_return] || :intermediates
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

    # Generate the expanded list of requested page numbers.
    def page_list(pages)
      pages.split(',').map { |range|
        if range.include?('-')
          range = range.split('-')
          Range.new(range.first.to_i, range.last.to_i).to_a.map {|n| n.to_i }
        else
          range.to_i
        end
      }.flatten.uniq.sort
    end

  end

end
