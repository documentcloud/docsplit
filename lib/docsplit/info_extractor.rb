module Docsplit

  # Delegates to **pdfinfo** in order to extract information about a PDF file.
  class InfoExtractor

    # Regex matchers for different bits of information.
    MATCHERS = {
      :author   => /^Author:\s+([^\n]+)/,
      :date     => /^CreationDate:\s+([^\n]+)/,
      :creator  => /^Creator:\s+([^\n]+)/,
      :keywords => /^Keywords:\s+([^\n]+)/,
      :producer => /^Producer:\s+([^\n]+)/,
      :subject  => /^Subject:\s+([^\n]+)/,
      :title    => /^Title:\s+([^\n]+)/,
      :length   => /^Pages:\s+([^\n]+)/,
    }

    # Pull out a single datum from a pdf.
    def extract(key, pdfs, opts)
      extract_all(pdfs, opts)[key]
    end
    
    def extract_all(pdfs, opts)
      pdf = [pdfs].flatten.first
      cmd = "pdfinfo #{ESCAPE[pdf]} 2>&1"
      result = `#{cmd}`.chomp
      raise ExtractionFailed, result if $? != 0
      # ruby  1.8 (iconv) and 1.9 (String#encode) :
      if String.method_defined?(:encode)
        result.encode!('UTF-8', 'UTF-8', :invalid => :replace)
      else
        require 'iconv' unless defined?(Iconv)
        ic = Iconv.new('UTF-8//IGNORE','UTF-8')
        result = ic.iconv(result)
      end
      info = {}
      MATCHERS.each do |key, matcher|
        match = result.match(matcher)
        answer = match && match[1]
        if answer
          answer = answer.to_i if key == :length
          info[key] = answer
        end
      end
      info
    end

  end

end
