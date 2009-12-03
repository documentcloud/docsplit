package org.documentcloud;

import java.util.List;
import java.text.SimpleDateFormat;

import org.icepdf.core.pobjects.Document;
import org.icepdf.core.pobjects.PInfo;
import org.icepdf.core.pobjects.PDate;

// Extracts metadata from a PDF file.
public class ExtractInfo extends Extractor {

  private Document doc;
  private PInfo info;
  private String key;

  // The list of metadata keys we know how to extract.
  private enum Keys {
    AUTHOR, DATE, CREATOR, KEYWORDS, PRODUCER, SUBJECT, TITLE
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
      doc = new Document();
      doc.setFile(pdfPath);
      info = doc.getInfo();
      String val = extractInfo();
      if (val != null) System.out.println(val);
      doc.dispose();
    } catch(Exception e) {
      System.out.println(e.getMessage());
      System.exit(1);
    }
  }

  // Use the PDDocumentInformation object to fetch metadata values as strings.
  public String extractInfo() {
    switch(Keys.valueOf(key)) {
      case AUTHOR:    return info.getAuthor();
      case CREATOR:   return info.getCreator();
      case KEYWORDS:  return info.getKeywords();
      case PRODUCER:  return info.getProducer();
      case SUBJECT:   return info.getSubject();
      case TITLE:     return info.getTitle();
      case DATE:
        PDate date = info.getCreationDate();
        if (date == null) return null;
        return date.getYear() + "-" + date.getMonth() + "-" + date.getDay();
      default:        return null;
    }
  }

}