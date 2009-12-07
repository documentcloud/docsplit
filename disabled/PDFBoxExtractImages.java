package org.documentcloud;

import java.awt.image.BufferedImage;
import java.awt.Dimension;
import java.awt.Color;
import java.awt.Graphics2D;
import java.io.IOException;
import java.io.File;
import java.util.List;

import javax.imageio.ImageIO;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdfviewer.PageDrawer;

// Use PDFBox's PDDocument and PDPage to convert every page of a document into
// into a rasterized image. Pass --format to change the image format, and --width
// to fix all images at a certain width.
public class ExtractImages extends Extractor {

  private final int     DEFAULT_RESOLUTION  = 72;
  private final String  DEFAULT_FORMAT      = "png";
  private final int     START_PAGE          = 1;
  private final int     END_PAGE            = Integer.MAX_VALUE;

  private PDDocument doc;
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
      doc = PDDocument.load(pdfPath);
      decrypt(doc);
      basename = getBasename(pdfPath);
      List pages = doc.getDocumentCatalog().getAllPages();
      for (int i=0; i<pages.size(); i++) writePageImage((PDPage) pages.get(i), i + 1);
      doc.close();
    } catch (IOException e) {
      System.out.println(e.getMessage());
      System.exit(1);
    }
  }

  private void writePageImage(PDPage page, int pageNumber) throws IOException {
    for (String targetWidth : imageWidths) {
      PDRectangle mBox = page.findMediaBox();
      int origWidth = (int) mBox.getWidth();
      int origHeight = (int) mBox.getHeight();
      Dimension pageDimension = new Dimension(origWidth, origHeight);

      int imageWidth, imageHeight;
      float scaleFactor;
      if (targetWidth == null) {
        imageWidth  = origWidth;
        imageHeight = origHeight;
        scaleFactor = 1.0f;
      } else {
        imageWidth  = Integer.parseInt(targetWidth);
        scaleFactor = (float) imageWidth / (float) origWidth;
        imageHeight = Math.round((float) origHeight * scaleFactor);
      }

      BufferedImage image = new BufferedImage(imageWidth, imageHeight, BufferedImage.TYPE_INT_RGB);
      Graphics2D graphics = (Graphics2D) image.getGraphics();
      graphics.setBackground(Color.WHITE);
      graphics.clearRect(0, 0, imageWidth, imageHeight);
      graphics.scale(scaleFactor, scaleFactor);
      PageDrawer drawer = new PageDrawer();
      drawer.drawPage(graphics, page, pageDimension);

      String prefix = imageWidths.length > 1 ? targetWidth + File.separator : "";
      for (String format : imageFormats) {
        String imagePath = prefix + basename + "_" + String.valueOf(pageNumber) + "." + format;
        ImageIO.write(image, format, outputFile(imagePath));
      }
    }
  }

}