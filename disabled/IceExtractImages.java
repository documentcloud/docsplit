package org.documentcloud;

import java.util.List;
import java.awt.Image;
import java.awt.image.BufferedImage;
import javax.imageio.ImageIO;
import java.io.File;
import java.io.IOException;

import org.icepdf.core.pobjects.Document;
import org.icepdf.core.pobjects.Page;
import org.icepdf.core.util.GraphicsRenderingHints;
import org.icepdf.core.pobjects.PDimension;

// Use ICEpdf's image support to convert every page of a document into
// into a rasterized image. Pass --format to change the image format, and --width
// to fix all images at a certain width.
public class ExtractImages extends Extractor {

  private final String  DEFAULT_FORMAT      = "png";

  private String basename;
  private String[] imageFormats = {DEFAULT_FORMAT};
  private String[] imageWidths = {null};

  // The mainline.
  public static void main(String[] args) {
    (new ExtractImages()).run(args);
  }

  // Handles "--format" and "--width" arguments.
  protected void parseArguments(List<String> args) {
    super.parseArguments(args);
    int formatLoc = args.indexOf("--format");
    if (formatLoc >= 0) {
      imageFormats = args.remove(formatLoc + 1).split(",");
      args.remove(formatLoc);
    }
    int widthLoc = args.indexOf("--width");
    if (widthLoc >= 0) {
      imageWidths = args.remove(widthLoc + 1).split(",");
      args.remove(widthLoc);
    }
  }

  // Convert all of the pages in the PDF located at the given path into images.
  public void extract(String pdfPath) {
    try {
      basename = getBasename(pdfPath);
      Document doc = new Document();
      doc.setFile(pdfPath);
      int numPages = doc.getNumberOfPages();
      for (int i=0; i<numPages; i++) writePageImage(doc, i);
      doc.dispose();
    } catch (Exception e) {
      System.out.println(e.getMessage());
      System.exit(1);
    }
  }

  // Write out a single page of the document as images, in a list of different
  // sizes and formats.
  private void writePageImage(Document doc, int index) throws IOException {
    PDimension dim = doc.getPageDimension(index, 0f);
    double origWidth = dim.getWidth(), origHeight = dim.getHeight();

    for (String targetWidth : imageWidths) {
      int imageWidth, imageHeight;
      double scaleFactor;
      if (targetWidth == null) {
        imageWidth  = (int) origWidth;
        imageHeight = (int) origHeight;
        scaleFactor = 1.0;
      } else {
        imageWidth = Integer.parseInt(targetWidth);
        scaleFactor = (double) imageWidth / origWidth;
        imageHeight = (int) Math.round(origHeight * scaleFactor);
      }

      BufferedImage image = (BufferedImage) doc.getPageImage(index, GraphicsRenderingHints.SCREEN, Page.BOUNDARY_CROPBOX, 0f, (float) scaleFactor);
      String prefix = imageWidths.length > 1 ? targetWidth + File.separator : "";
      for (String format : imageFormats) {
        String imagePath = prefix + basename + "_" + String.valueOf(index + 1) + "." + format;
        ImageIO.write(image, format, outputFile(imagePath));
      }
    }
  }

}