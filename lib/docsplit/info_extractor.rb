module Docsplit

  # Delegates to **pdfinfo** in order to extract information about a PDF file.
  class InfoExtractor

    # Regex matchers for different bits of information.
    MATCHERS = {
      :author   => Regexp.new("^Author:\s+([^\n]+)".encode('UTF-8')),
      :date     => Regexp.new("^CreationDate:\s+([^\n]+)".encode('UTF-8')),
      :creator  => Regexp.new("^Creator:\s+([^\n]+)".encode('UTF-8')),
      :keywords => Regexp.new("^Keywords:\s+([^\n]+)".encode('UTF-8')),
      :producer => Regexp.new("^Producer:\s+([^\n]+)".encode('UTF-8')),
      :subject  => Regexp.new("^Subject:\s+([^\n]+)".encode('UTF-8')),
      :title    => Regexp.new("^Title:\s+([^\n]+)".encode('UTF-8')),
      :length   => Regexp.new("^Pages:\s+([^\n]+)".encode('UTF-8')),
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

  end

end
