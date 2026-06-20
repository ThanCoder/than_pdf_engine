#pragma once

#include <cstdint>
#include <string>
#include <vector>
extern "C" {
#include <fpdfview.h>
#include <stb_image_write.h>
}
class PdfPage {
 private:
  FPDF_DOCUMENT doc = nullptr;
  FPDF_PAGE page = nullptr;
  FPDF_BITMAP current_bitmap = nullptr;
  int width = 0;
  int height = 0;
  int width_f = 0;
  int height_f = 0;

 public:
  PdfPage(FPDF_DOCUMENT doc = nullptr, FPDF_PAGE page = nullptr);
  ~PdfPage();

  std::uint8_t* getBitmapSourcePtr(int targetWidth, int targetHeight);

  std::vector<uint8_t> renderToRGBAWithDeviceWidth(int targetWidth,
                                                   int targetHeight);

  double getOriginalWidth();
  double getOriginalHeight();

  std::vector<uint8_t> renderToJpegWH(int width, int height, int quality = 90);
  bool saveAsPngWH(const std::string& outPath, int width, int height);
  bool saveAsJpgWH(const std::string& outPath, int width, int height,
                   int quality = 90);
};