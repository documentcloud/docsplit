package org.documentcloud;

import java.util.List;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.util.Splitter;
import org.apache.pdfbox.pdfwriter.COSWriter;
import org.apache.pdfbox.exceptions.COSVisitorException;

// Use PDFBox's Splitter to break apart a large PDF into individual pages.
public class ExtractPages extends Extractor {

  private PDDocument doc;
  private String basename;

  // The mainline.
  public static void main(String[] args) {
    (new ExtractPages()).run(args);
  }

  // Extract each page of the given PDF.
  public void extract(String pdfPath) {
    try {
      basename  = getBasename(pdfPath);
      doc = PDDocument.load(pdfPath);
      decrypt(doc);
      List pages = (new Splitter()).split(doc);
      if (pageNumbers != null) {
        for (Integer num : pageNumbers) writePage((PDDocument) pages.get(num.intValue()- 1), num.intValue());
      } else {
        for (int i=0; i<pages.size(); i++) writePage((PDDocument) pages.get(i), i + 1);
      }
      doc.close();
    } catch(Exception e) {
      System.out.println(e.getMessage());
      System.exit(1);
    }
  }

  // Writes out a page as a single-page PDF.
  private void writePage(PDDocument page, int pageNumber) throws IOException, COSVisitorException {
    String pageName       = basename + "_" + String.valueOf(pageNumber) + ".pdf";
    FileOutputStream out  = new FileOutputStream(outputFile(pageName));
    COSWriter writer      = new COSWriter(out);
    writer.write(page);
    out.close();
    writer.close();
    page.close();
  }

}
