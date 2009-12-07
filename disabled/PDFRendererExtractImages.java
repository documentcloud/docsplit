package org.documentcloud;

import java.util.List;
import java.awt.Image;
import java.awt.image.BufferedImage;
import java.awt.Graphics2D;
import java.awt.Rectangle;
import java.awt.Color;
import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import javax.imageio.ImageIO;

import com.sun.pdfview.PDFFile;
import com.sun.pdfview.PDFPage;

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
      FileChannel channel = (new RandomAccessFile(new File(pdfPath), "r")).getChannel();
      ByteBuffer buf = channel.map(FileChannel.MapMode.READ_ONLY, 0, channel.size());
      PDFFile pdf = new PDFFile(buf);
      int numPages =  pdf.getNumPages();
      for (int i=0; i<numPages; i++) writePageImage(pdf.getPage(i), i + 1);
    } catch (IOException e) {
      System.out.println(e.getMessage());
      System.exit(1);
    }
  }

  private void writePageImage(PDFPage page, int pageNumber) throws IOException {
    double origWidth = page.getBBox().getWidth();
    double origHeight = page.getBBox().getHeight();

    for (String targetWidth : imageWidths) {
      int imageWidth, imageHeight;
      double scaleFactor;
      if (targetWidth == null) {
        imageWidth  = (int) origWidth;
        imageHeight = (int) origHeight;
        scaleFactor = 1.0f;
      } else {
        imageWidth  = Integer.parseInt(targetWidth);
        scaleFactor = (double) imageWidth / origWidth;
        imageHeight = (int) Math.round(origHeight * scaleFactor);
      }
      Rectangle rect = new Rectangle(0, 0, (int) origWidth, (int) origHeight);

      Image image = page.getImage(imageWidth, imageHeight, rect, null, true, true);
      BufferedImage bImage = toBufferedImage(image);

      String prefix = imageWidths.length > 1 ? targetWidth + File.separator : "";
      for (String format : imageFormats) {
        String imagePath = prefix + basename + "_" + String.valueOf(pageNumber) + "." + format;
        ImageIO.write(bImage, format, outputFile(imagePath));
      }
    }
  }

  private BufferedImage toBufferedImage(Image image) {
    int w = image.getWidth(null), h = image.getHeight(null);
    BufferedImage bImage = new BufferedImage(w, h, BufferedImage.TYPE_INT_RGB);
    Graphics2D g = bImage.createGraphics();
    g.setBackground(Color.WHITE);
    g.clearRect(0, 0, w, h);
    g.drawImage(image, 0, 0, null);
    g.dispose();
    return bImage;
  }

}