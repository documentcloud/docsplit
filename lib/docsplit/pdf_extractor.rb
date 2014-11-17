require 'rbconfig'

module Docsplit
  class PdfExtractor
    @@executable     = nil
    @@version_string = nil

    # Provide a set of helper functions to determine the OS.
    HOST_OS = (defined?("RbConfig") ? RbConfig : Config)::CONFIG['host_os']
    def windows?
      !!HOST_OS.match(/mswin|windows|cygwin/i)
    end
    def osx?
      !!HOST_OS.match(/darwin/i)
    end
    def linux?
      !!HOST_OS.match(/linux/i)
    end
    
    # The first line of the help output holds the name and version number
    # of the office software to be used for extraction.
    def version_string
      unless @@version_string
        null = windows? ? "NUL" : "/dev/null"
        @@version_string = `#{office_executable} -h 2>#{null}`.split("\n").first
        if !!@@version_string.match(/[0-9]*/)
          @@version_string = `#{office_executable} --version`.split("\n").first
        end
      end
      @@version_string
    end
    def libre_office?
      !!version_string.match(/^LibreOffice/)
    end
    def open_office?
      !!version_string.match(/^OpenOffice.org/)
    end
    
    # A set of default locations to search for office software
    # These have been extracted from JODConverter.  Each listed
    # path should contain a directory "program" which in turn 
    # contains the "soffice" executable.
    # see: https://github.com/mirkonasato/jodconverter/blob/master/jodconverter-core/src/main/java/org/artofsolving/jodconverter/office/OfficeUtils.java#L63-L91
    def office_search_paths
      if windows?
        office_names       = ["LibreOffice 3", "LibreOffice 4", "OpenOffice.org 3"]
        program_files_path = ENV["CommonProgramFiles"]
        search_paths       = office_names.map{ |program| File.join(program_files_path, program) }
      elsif osx?
        search_paths = %w(
          /Applications/LibreOffice.app/Contents
          /Applications/OpenOffice.org.app/Contents
        )
      else # probably linux/unix
        # heroku libreoffice buildpack: https://github.com/rishihahs/heroku-buildpack-libreoffice
        search_paths = %w(
          /usr/lib/libreoffice
          /usr/lib64/libreoffice
          /opt/libreoffice
          /usr/lib/openoffice
          /usr/lib64/openoffice
          /opt/openoffice.org3
          /app/vendor/libreoffice
          /usr/local/bin
        )
      end
      search_paths
    end
    
    # Identify the path to a working office executable.
    def office_executable
      paths = office_search_paths

      # If an OFFICE_PATH has been specified on the commandline
      # raise an error if that path isn't valid, otherwise, add
      # it to the front of our search paths.
      if ENV['OFFICE_PATH']
        raise ArgumentError, "No such file or directory #{ENV['OFFICE_PATH']}" unless File.exists? ENV['OFFICE_PATH']
        paths.unshift(ENV['OFFICE_PATH'])
      end
      
      # The location of the office executable is OS dependent
      path_pieces = ["soffice"]
      if windows?
        path_pieces += [["program", "soffice.bin"]]
      elsif osx?
        path_pieces += [["MacOS", "soffice"], ["Contents", "MacOS", "soffice"]]
      else
        path_pieces += [["program", "soffice"]]
      end
      
      # Search for the first suitable office executable
      # and short circuit an executable is found.
      paths.each do |path|
        if File.exists? path
          @@executable ||= path unless File.directory? path
          path_pieces.each do |pieces|
            check_path = File.join(path, pieces)
            @@executable ||= check_path if File.exists? check_path
          end
        end
        break if @@executable
      end
      raise OfficeNotFound, "No office software found" unless @@executable
      @@executable
    end
    
    # Used to specify the office location for JODConverter
    def office_path
      File.dirname(File.dirname(office_executable))
    end
    
    # Convert documents to PDF.
    def extract(docs, opts)
      out = opts[:output] || '.'
      FileUtils.mkdir_p out unless File.exists?(out)
      [docs].flatten.each do |doc|
        ext = File.extname(doc)
        basename = File.basename(doc, ext)
        escaped_doc, escaped_out, escaped_basename = [doc, out, basename].map(&ESCAPE)

        if GM_FORMATS.include?(`file -b --mime #{ESCAPE[doc]}`.strip.split(/[:;]\s+/)[0])
          `gm convert #{escaped_doc} #{escaped_out}/#{escaped_basename}.pdf`
        else
          if libre_office?
            # Set the LibreOffice user profile, so that parallel uses of cloudcrowd don't trip over each other.
            ENV['SYSUSERCONFIG']="file://#{File.expand_path(escaped_out)}"
            
            options = "--headless --invisible  --norestore --nolockcheck --convert-to pdf --outdir #{escaped_out} #{escaped_doc}"
            cmd = "#{office_executable} #{options} 2>&1"
            result = `#{cmd}`.chomp
            raise ExtractionFailed, result if $? != 0
            true
          else # open office presumably, rely on JODConverter to figure it out.
            options = "-jar #{ESCAPED_ROOT}/vendor/jodconverter/jodconverter-core-3.0-beta-4.jar -r #{ESCAPED_ROOT}/vendor/conf/document-formats.js"
            run_jod "#{options} #{escaped_doc} #{escaped_out}/#{escaped_basename}.pdf", [], {}
          end
        end
      end
    end

    CLASSPATH     = "#{ESCAPED_ROOT}/build#{File::PATH_SEPARATOR}#{ESCAPED_ROOT}/vendor/'*'"

    LOGGING       = "-Djava.util.logging.config.file=#{ESCAPED_ROOT}/vendor/logging.properties"

    HEADLESS      = "-Djava.awt.headless=true"
    
    private
    
    # Runs a Java command, with quieted logging, and the classpath set properly.
    def run_jod(command, pdfs, opts, return_output=false)

      pdfs   = [pdfs].flatten.map{|pdf| "\"#{pdf}\""}.join(' ')
      office = osx? ? "-Doffice.home=#{office_path}" : office_path
      cmd    = "java #{HEADLESS} #{LOGGING} #{office} -cp #{CLASSPATH} #{command} #{pdfs} 2>&1"
      result = `#{cmd}`.chomp
      raise ExtractionFailed, result if $? != 0
      return return_output ? (result.empty? ? nil : result) : true
    end

    class OfficeNotFound < StandardError; end
  end
end
