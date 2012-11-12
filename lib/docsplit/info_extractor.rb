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
      pdf = [pdfs].flatten.first
      cmd = "pdfinfo #{ESCAPE[pdf]} 2>&1"
      result = `#{cmd}`.chomp
      raise ExtractionFailed, result if $? != 0
      match = result.match(MATCHERS[key])
      answer = match && match[1]
      answer = answer.to_i if answer && key == :length
      answer
    end
    
    # Pull all supported datums from a pdf.
    def extract_all(pdfs, opts)
      pdf = [pdfs].flatten.first
      cmd = "pdfinfo #{ESCAPE[pdf]} 2>&1"
      result = `#{cmd}`.chomp
      raise ExtractionFailed, result if $? != 0
      
      answers = {}
      MATCHERS.each do |key, pattern|
        match = result.match(pattern)
        answer = match && match[1]
        if answer
          answer = answer.to_i if key == :length
          answers[key] = answer
        end
      end
      answers
    end

  end

end