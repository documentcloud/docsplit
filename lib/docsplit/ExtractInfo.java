package org.documentcloud;

import java.util.List;
import java.io.IOException;
import java.text.SimpleDateFormat;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDDocumentInformation;

// Extracts metadata from a PDF file.
public class ExtractInfo extends Extractor {

  private PDDocument doc;
  private PDDocumentInformation info;
  private String key;

  // The list of metadata keys we know how to extract.
  private enum Keys {
    AUTHOR, DATE, CREATOR, KEYWORDS, PRODUCER, SUBJECT, TITLE, LENGTH
  }

  // The mainline.
  public static void main(String[] args) {
    (new ExtractInfo()).run(args);
  }

  // The first argument is always the name of the metadata key.
  protected void parseArguments(List<String> args) {
    super.parseArguments(args);
    key = args.remove(0).toUpperCase();
  }

  // Extract the configured bit of metadata from a PDF, decrypting if necessary.
  public void extract(String pdfPath) {
    try {
      doc = PDDocument.load(pdfPath, false);
      decrypt(doc);
      info = doc.getDocumentInformation();
      String val = extractInfo();
      if (val != null) System.out.println(val);
      doc.close();
    } catch(IOException e) {
      System.out.println(e.getMessage());
      System.exit(1);
    }
  }

  // Use the PDDocumentInformation object to fetch metadata values as strings.
  public String extractInfo() throws IOException {
    switch(Keys.valueOf(key)) {
      case AUTHOR:    return info.getAuthor();
      case DATE:      return new SimpleDateFormat("yyyy-MM-dd").format(info.getCreationDate().getTime());
      case CREATOR:   return info.getCreator();
      case KEYWORDS:  return info.getKeywords();
      case PRODUCER:  return info.getProducer();
      case SUBJECT:   return info.getSubject();
      case TITLE:     return info.getTitle();
      case LENGTH:    return String.valueOf(doc.getNumberOfPages());
      default:        return null;
    }
  }

}