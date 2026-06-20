#pragma once
// #define STB_IMAGE_WRITE_IMPLEMENTATION

#include <string>
#include <vector>

#include "pdf_page.hpp"
extern "C" {
#include <fpdfview.h>
#include <stb_image_write.h>
}

struct PageCacheData {
  int pageIndex;
  int width;
  int height;
  std::vector<uint8_t> rgbaData;
};

struct PageSizeData {
  float width;
  float height;
};
class PdfCore {
 private:
  FPDF_DOCUMENT doc = nullptr;

 public:
  PdfCore();
  ~PdfCore();
  bool openFile(const std::string& path, const std::string& password = "");
  bool openMemoryRaw(const unsigned char* dataBuffer, int dataSize,
                     const std::string& password = "");
  bool openMemory64Raw(const unsigned char* dataBuffer, int dataSize,
                       const std::string& password = "");
  int getPageCount();
  PdfPage getPage(int pageIndex);
  PdfPage* getPagePtr(int pageIndex);
  std::vector<PageSizeData> getAllPageSizes();
};
