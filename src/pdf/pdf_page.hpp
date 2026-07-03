#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "pdf_core.hpp"
extern "C" {
#include <fpdfview.h>
#include <stb_image_write.h>
}
class PdfPage {
 private:
  PdfCore* core = nullptr;
  FPDF_PAGE page = nullptr;
  FPDF_BITMAP current_bitmap = nullptr;
  double width = 0;
  double height = 0;
  double width_f = 0;
  double height_f = 0;

 public:
  PdfPage(PdfCore* core, int pageIndex);
  ~PdfPage();

  std::uint8_t* getBitmapSourcePtr(int targetWidth, int targetHeight);

  std::vector<uint8_t> renderToRGBAWithDeviceWidth(int targetWidth,
                                                   int targetHeight);

  double getWidth() { return width; }
  double getHeight() { return height; }

  double getWidthF() { return width_f; }
  double getHeightF() { return height_f; }

  bool isValid() { return core != nullptr && page != nullptr; }

  std::vector<uint8_t> renderToJpegWH(int targetWidth, int targetHeight,
                                      int quality = 90);
  bool saveAsPngWH(const std::string& outPath, int targetWidth,
                   int targetHeight);
  bool saveAsJpgWH(const std::string& outPath, int targetWidth,
                   int targetHeight, int quality = 90);
};