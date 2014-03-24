module Docsplit

  # Include a method to transparently convert non-PDF arguments to temporary
  # PDFs. Allows us to pretend to natively support docs, rtf, ppt, and so on.
  module TransparentPDFs

    # Temporarily convert any non-PDF documents to PDFs before running them
    # through further extraction.
    def ensure_pdfs(docs)
      [docs].flatten.map do |doc|
        if is_pdf?(doc)
          doc
        else
          tempdir = File.join(Dir.tmpdir, 'docsplit')
          extract_pdf([doc], {:output => tempdir})
          File.join(tempdir, File.basename(doc, File.extname(doc)) + '.pdf')
        end
      end
    end

    def is_pdf?(doc)
      File.extname(doc).downcase == '.pdf' || File.open(doc, 'rb', &:readline) =~ /\A\%PDF-\d+(\.\d+)?/
    end

  end

  extend TransparentPDFs

end
