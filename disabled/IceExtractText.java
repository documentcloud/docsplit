package org.documentcloud;

import java.util.List;
import java.util.Enumeration;
import java.io.IOException;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;

import org.icepdf.core.pobjects.Document;
import org.icepdf.core.pobjects.Page;

// Uses PDFBox's PDFTextStripper to extract the full, plain, UTF-8 text of a
// PDF document. Pass --pages to write out the plain text for each individual
// page; --pages-only to omit the text for the entire document.
public class ExtractText extends Extractor {

  private boolean   writePages = false;
  private boolean   writeText  = true;
  private Document  doc;
  private String    basename;

  // The mainline.
  public static void main(String[] args) {
    (new ExtractText()).run(args);
  }

  // Handle --pages and --pages-only arguments.
  protected void parseArguments(List<String> args) {
    super.parseArguments(args);
    boolean pages = args.remove("--pages");
    boolean only  = args.remove("--pages-only");
    writePages    = pages || only;
    writeText     = !only;
  }

  // Extract the plain text for a PDF, and write it into the requested output
  // sizes.
  public void extract(String pdfPath) {
    try {
      basename = getBasename(pdfPath);
      doc = new Document();
      doc.setFile(pdfPath);
      if (writeText)  writeFullText();
      if (writePages) writePageText();
      doc.dispose();
    } catch(Exception e) {
      System.out.println(e.getMessage());
      System.exit(1);
    }
  }

  // Write out the extracted full text for the entire PDF.
  public void writeFullText() throws IOException {
    OutputStreamWriter output = new OutputStreamWriter(new FileOutputStream(outputFile(basename + ".txt")), "UTF-8");
    extractTextForPageRange(output, 0, Integer.MAX_VALUE);
    output.close();
  }

  // Write out the full text for each page separately.
  public void writePageText() throws IOException {
    int pages = doc.getNumberOfPages();
    for (int i=0; i<pages; i++) {
      OutputStreamWriter output = new OutputStreamWriter(new FileOutputStream(outputFile(basename + "_" + String.valueOf(i + 1) + ".txt")), "UTF-8");
      extractTextForPageRange(output, i, i);
      output.close();
    }
  }

  // Internal method to writes out text from the PDF for a given page range
  // to a provided output stream.
  private void extractTextForPageRange(OutputStreamWriter output, int startPage, int endPage) throws IOException {
    for (int i = startPage; i <= endPage; i++) {
      Enumeration pageText = doc.getPageText(i).elements();
      while (pageText.hasMoreElements()) {
        StringBuffer text = (StringBuffer) pageText.nextElement();
        if (text != null) output.write(text.toString());
      }
    }
  }

}