module Docsplit

  # Include a method to transparently convert non-PDF arguments to temporary
  # PDFs. Allows us to pretend to natively support docs, rtf, ppt, and so on.
  module TransparentPDFs

    # Temporarily convert any non-PDF documents to PDFs before running them
    # through further extraction.
    def ensure_pdfs(docs)
      [docs].flatten.map do |doc|
        ext = File.extname(doc)
        if ext.downcase == '.pdf' || File.open(doc, &:readline) =~ /\A\%PDF-\d+(\.\d+)?$/
          doc
        else 
          #this test is nested because it's relatively expensive, no need to do it for files with pdf extensions
          filetypeHeader = File.open(doc, 'r') { |f| f.read(4)}
          is_pdf = (filetypeHeader =~ /\%PDF/) == 0 
          #via http://stackoverflow.com/questions/7919674/how-to-verify-downloaded-file-format
          if is_pdf
            doc
          else
            tempdir = File.join(Dir.tmpdir, 'docsplit')
            extract_pdf([doc], {:output => tempdir})
            File.join(tempdir, File.basename(doc, ext) + '.pdf')
          end
        end
      end
    end

  end

  extend TransparentPDFs

end
