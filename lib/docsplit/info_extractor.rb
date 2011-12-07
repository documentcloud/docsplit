require 'iconv'

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
      # Remove non-ASCII characters as the matcher chokes on them
      result = Iconv.conv('ASCII//IGNORE', 'UTF8', `#{cmd}`.chomp)
      raise ExtractionFailed, result if $? != 0
      match = result.match(MATCHERS[key])
      answer = match && match[1]
      answer = answer.to_i if answer && key == :length
      answer
    end

  end

end