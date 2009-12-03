package org.documentcloud;

import java.io.File;
import java.util.List;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.Iterator;

import org.apache.pdfbox.pdmodel.PDDocument;

// The base Extractor class contains the common functionality needed to run
// command-line extractors.
public abstract class Extractor {

  protected File output;
  protected boolean allPages = false;
  protected ArrayList<Integer> pageNumbers;

  // Running an extractor consists of converting the arguments array into a
  // more manageable List, parsing arguments, and extracting pdfs.
  public void run(String[] arguments) {
    List<String> args = new ArrayList<String>(Arrays.asList(arguments));
    parseArguments(args);
    Iterator<String> iter = args.iterator();
    while(iter.hasNext()) extract(iter.next());
  }

  // Subclasses must override "extract" to perform their specific extraction.
  public abstract void extract(String pdfPath);

  // The default "parseArguments" method handles common arguments.
  protected void parseArguments(List<String> args) {
    int dirLoc = args.indexOf("--output");
    if (dirLoc >= 0) {
      output = new File(args.remove(dirLoc + 1));
      args.remove(dirLoc);
    }
    int pagesLoc = args.indexOf("--pages");
    if (pagesLoc >= 0) {
      parsePages(args.remove(pagesLoc + 1));
      args.remove(pagesLoc);
    }
  }

  // Utility function to get the basename of a file path.
  // After File.basename in Ruby.
  public String getBasename(String pdfPath) {
    String basename = new File(pdfPath).getName();
    return basename.substring(0, basename.lastIndexOf('.'));
  }

  // Get a reference to an output file, placed inside any configured directories,
  // while ensuring that parent directories exist.
  public File outputFile(String path) {
    File file = output != null ? new File(output, path) : new File(path);
    File parent = file.getParentFile();
    if (parent != null) parent.mkdirs();
    return file;
  }

  // Decrypt a non-passworded but still encrypted document.
  public void decrypt(PDDocument doc) {
    if (!doc.isEncrypted()) return;
    try {
      doc.decrypt("");
    } catch (Exception e) {
      System.out.println("Error decrypting document, details: " + e.getMessage());
      System.exit(1);
    }
  }

  private void parsePages(String pageList) {
    if (pageList.equals("all")) {
      allPages = true;
      return;
    }
    pageNumbers = new ArrayList<Integer>();
    String[] groups = pageList.split(",");
    for (String group : groups) {
      if (group.contains("-")) {
        String[] range = group.split("-");
        int start = Integer.parseInt(range[0]);
        int end = Integer.parseInt(range[1]);
        for (int i=start; i<=end; i++) pageNumbers.add(new Integer(i));
      } else {
        pageNumbers.add(new Integer(Integer.parseInt(group)));
      }
    }
  }

}