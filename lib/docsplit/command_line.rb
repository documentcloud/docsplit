require 'optparse'
require File.expand_path(File.dirname(__FILE__) + '/../docsplit')

module DocSplit

  # A single command-line utility to separate a PDF into all its component parts.
  class CommandLine

    BANNER = <<-EOS
docsplit breaks apart documents into images, text, or individual pages.
It wraps PDFBox, GraphicsMagick, and JODConverter.

Usage:
  docsplit COMMAND [OPTIONS] path/to/doc.pdf
  Main commands:
    pages, images, text, pdf.
  Metadata commands:
    author, date, creator, keywords, producer, subject, title, length.

Example:
  docsplit images --size 700x --format jpg document.pdf

Dependencies:
  Ruby, Java, A working GraphicsMagick (gm) command,
  and a headless OpenOffice server for non-PDF documents.

Options:
    (size, pages and format can take comma-separated values)

    EOS

    # Creating a CommandLine runs off of the contents of ARGV.
    def initialize
      parse_options
      cmd = ARGV.shift
      @command = cmd && cmd.to_sym
      run
    end

    # Delegate to the DocSplit Ruby API to perform all extractions.
    def run
      begin
        case @command
        when :images  then DocSplit.extract_images(ARGV, @options)
        when :pages   then DocSplit.extract_pages(ARGV, @options)
        when :text    then DocSplit.extract_text(ARGV, @options)
        when :pdf     then DocSplit.extract_pdf(ARGV, @options)
        else
          if METADATA_KEYS.include?(@command)
            value = DocSplit.send("extract_#{@command}", ARGV, @options)
            puts value unless value.nil?
          else
            usage
          end
        end
      rescue ExtractionFailed => e
        puts e.message.chomp
        exit(1)
      end
    end

    # Print out the usage help message.
    def usage
      puts "\n#{@option_parser}\n"
      exit
    end


    private

    # Use the OptionParser library to parse out all supported options. Return
    # options formatted for the Ruby API.
    def parse_options
      @options = {}
      @option_parser = OptionParser.new do |opts|
        opts.on('-o', '--output [DIR]', 'set the directory for all output') do |d|
          @options[:output] = d
        end
        opts.on('-p', '--pages [PAGES]', "extract specific pages (eg: 5-10)") do |p|
          @options[:pages] = p
        end
        opts.on('-s', '--size [SIZE]', 'set a fixed size (eg: 50x75)') do |s|
          @options[:size] = s.split(',')
        end
        opts.on('-f', '--format [FORMAT]', 'set image format (pdf, jpg, gif...)') do |t|
          @options[:format] = t.split(',')
        end
        opts.on_tail('-v', '--version', 'display docsplit version') do
          puts "docsplit version #{DocSplit::VERSION}"
          exit
        end
        opts.on_tail('-h', '--help', 'display this help message') do
          usage
        end
      end
      @option_parser.banner = BANNER
      @option_parser.parse!(ARGV)
    end

  end

end