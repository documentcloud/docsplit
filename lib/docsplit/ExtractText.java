package org.documentcloud;

import java.util.List;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.util.PDFTextStripper;

// Uses PDFBox's PDFTextStripper to extract the full, plain, UTF-8 text of a
// PDF document. Pass --pages to write out the plain text for each individual
// page; --pages-only to omit the text for the entire document.
public class ExtractText extends Extractor {

  private PDDocument doc;
  private String basename;

  // The mainline.
  public static void main(String[] args) {
    (new ExtractText()).run(args);
  }

  // Extract the plain text for a PDF, and write it into the requested output
  // sizes.
  public void extract(String pdfPath) {
    try {
      basename = getBasename(pdfPath);
      doc = PDDocument.load(pdfPath, false);
      decrypt(doc);
      if (allPages || (pageNumbers != null)) {
        writePageText();
      } else {
        writeFullText();
      }
      doc.close();
    } catch(IOException e) {
      System.out.println(e.getMessage());
      System.exit(1);
    }
  }

  // Write out the extracted full text for the entire PDF.
  public void writeFullText() throws IOException {
    OutputStreamWriter output = new OutputStreamWriter(new FileOutputStream(outputFile(basename + ".txt")), "UTF-8");
    extractTextForPageRange(output, 1, Integer.MAX_VALUE);
    output.close();
  }

  // Write out the full text for each specified page.
  public void writePageText() throws IOException {
    if (pageNumbers != null) {
      for (Integer num : pageNumbers) writePageText(num.intValue());
    } else {
      int pages = doc.getNumberOfPages();
      for (int i=1; i<=pages; i++) writePageText(i);
    }
  }

  // Write out the full text for a single page.
  public void writePageText(int pageNumber) throws IOException {
    File outfile = outputFile(basename + "_" + String.valueOf(pageNumber) + ".txt");
    OutputStreamWriter output = new OutputStreamWriter(new FileOutputStream(outfile), "UTF-8");
    extractTextForPageRange(output, pageNumber, pageNumber);
    output.close();
  }

  // Internal method to writes out text from the PDF for a given page range
  // to a provided output stream.
  private void extractTextForPageRange(OutputStreamWriter output, int startPage, int endPage) throws IOException {
    PDFTextStripper stripper = new PDFTextStripper("UTF-8");
    stripper.setSortByPosition(false);
    stripper.setShouldSeparateByBeads(true);
    stripper.setStartPage(startPage);
    stripper.setEndPage(endPage);
    stripper.writeText(doc, output);
  }

}