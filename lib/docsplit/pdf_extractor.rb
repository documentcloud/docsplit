require 'rbconfig'

module Docsplit
  class PdfExtractor
    CLASSPATH     = "#{ESCAPED_ROOT}/build#{File::PATH_SEPARATOR}#{ESCAPED_ROOT}/vendor/'*'"

    LOGGING       = "-Djava.util.logging.config.file=#{ESCAPED_ROOT}/vendor/logging.properties"

    HEADLESS      = "-Djava.awt.headless=true"

    HOST_OS = (defined?("Config") ? Config : RbConfig)::CONFIG['host_os']
    
    def self.windows?
      !!HOST_OS.match(/mswin|windows|cygwin/i)
    end
    
    def self.osx?
      !!HOST_OS.match(/darwin/i)
    end
    
    def self.linux?
      !!HOST_OS.match(/linux/i)
    end
    
    def self.version_string
      @@help ||= `#{self.office_executable} -h 2>&1`.split("\n").first
    end
    
    def self.libre_office?
      !!self.version_string.match(/^LibreOffice/)
    end

    def self.open_office?
      !!self.version_string.match(/^OpenOffice.org/)
    end
    
    def self.office_search_paths
      if self.windows?
        office_names       = ["LibreOffice 3", "LibreOffice 4", "OpenOffice.org 3"]
        program_files_path = ENV["CommonProgramFiles"]
        search_paths       = office_name.map{ |program| File.join(program_files_path, program) }
      elsif self.osx?
        search_paths = %w(
          /Applications/LibreOffice.app/Contents/program
          /Applications/OpenOffice.org.app/Contents/MacOS
        )
      else # probably linux/unix
        search_paths = %w(
          /usr/lib/libreoffice
          /opt/libreoffice
          /usr/lib/openoffice
          /opt/openoffice.org3
        )
      end
      search_paths.compact
    end
    
    def self.office_executable
      paths = self.office_search_paths

      if ENV['OFFICE_PATH']
        raise ArgumentError, "No such file or directory #{ENV['OFFICE_PATH']}" unless File.exists? ENV['OFFICE_PATH']
        paths.unshift(ENV['OFFICE_PATH'])
      end
      
      paths.each do |path|
        if File.exists? path
          @@executable ||= path unless File.directory? path
          path_pieces = [ "soffice", ["MacOS", "soffice"], ["Contents", "MacOS", "soffice"], 
                                     ["program", "soffice"], ["Contents", "program", "soffice"] ]
          path_pieces.each do |pieces|
            check_path = File.join(path, pieces)
            @@executable ||= check_path if File.exists? check_path
          end
          break if @@executable
        end
      end
      @@executable
    end
    
    def extract_pdfs(docs, opts)
      out = opts[:output] || '.'
      FileUtils.mkdir_p out unless File.exists?(out)
      [docs].flatten.each do |doc|
        ext = File.extname(doc)
        basename = File.basename(doc, ext)
        escaped_doc, escaped_out, escaped_basename = [doc, out, basename].map(&ESCAPE)

        if GM_FORMATS.include?(`file -b --mime #{ESCAPE[doc]}`.strip.split(/[:;]\s+/)[0])
          `gm convert #{escaped_doc} #{escaped_out}/#{escaped_basename}.pdf`
        else
          #options = "-jar #{ESCAPED_ROOT}/vendor/jodconverter/jodconverter-core-3.0-beta-4.jar -r #{ESCAPED_ROOT}/vendor/conf/document-formats.js"
          #run "#{options} #{escaped_doc} #{escaped_out}/#{escaped_basename}.pdf", [], {}
          
          if self.class.libre_office?
            puts "Libre!"

          elsif self.class.open_office?
            puts "Open!"
            
          else
            puts "Wha?"
          end
        end
      end
    end
    
    private
    
    # Runs a Java command, with quieted logging, and the classpath set properly.
    def run(command, pdfs, opts, return_output=false)
      pdfs    = [pdfs].flatten.map{|pdf| "\"#{pdf}\""}.join(' ')
      cmd     = "java #{HEADLESS} #{LOGGING} #{OFFICE} -cp #{CLASSPATH} #{command} #{pdfs} 2>&1"
      result  = `#{cmd}`.chomp
      raise ExtractionFailed, result if $? != 0
      return return_output ? (result.empty? ? nil : result) : true
    end

    def extract_options(options)
      
    end
  end
end
