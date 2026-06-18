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
  // Zoom factor လက်ခံပြီး JPEG data (bytes) ပြန်ပေးမယ့် Function
  std::uint8_t* getBitmapSourcePtr(int targetWidth, int targetHeight);
  std::vector<uint8_t> renderToRGBA(float zoomFactor);
  std::vector<uint8_t> renderToJpeg(int deviceWidth, float zoomFactor,
                                    int quality = 90);
  bool saveAsPng(const std::string& outPath, float zoomFactor);
  bool saveAsJpg(const std::string& outPath, float zoomFactor,
                 int quality = 90);

  int getRenderWith(float zoomFactor) {
    return static_cast<int>(width_f * zoomFactor);
  }
  int getRenderHeight(float zoomFactor) {
    return static_cast<int>(height_f * zoomFactor);
  }
  static PdfPage* createPagePtrFromDom(FPDF_DOCUMENT dom, int pageIndex) {
    auto page = FPDF_LoadPage(dom, pageIndex);
    return new PdfPage{dom, page};
  }

  std::vector<uint8_t> renderToRGBAWithDeviceWidth(int targetWidth,
                                                   int targetHeight);

  double getOriginalWidth();
  double getOriginalHeight();
};