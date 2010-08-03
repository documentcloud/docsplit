module Docsplit

  # Delegates to **pdfinfo** in order to extract information about a PDF file.
  class InfoExtractor

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

    def extract(key, pdfs, opts)
      pdf = [pdfs].flatten.first
      cmd = "pdfinfo #{pdf}"
      result = `#{cmd}`.chomp
      raise ExtractionFailed, result if $? != 0
      match = result.match(MATCHERS[key])
      answer = match && match[1]
      answer = answer.to_i if answer && key == :length
      answer
    end

  end

end