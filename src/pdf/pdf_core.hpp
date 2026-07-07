#pragma once

#include <string>
#include <vector>

extern "C" {
#include <fpdfview.h>
#include <stb_image_write.h>
}

struct PageSizeData {
  float width;
  float height;
};
class PdfCore {
 private:
  FPDF_DOCUMENT doc = nullptr;
  bool isFileOpened = false;

 public:
  PdfCore() = default;
  ~PdfCore();
  bool openFile(const std::string& path, const std::string& password = "");
  bool openMemoryRaw(const unsigned char* dataBuffer, int dataSize,
                     const std::string& password = "");
  bool openMemory64Raw(const unsigned char* dataBuffer, int dataSize,
                       const std::string& password = "");
  bool fileOpened() { return isFileOpened; }
  FPDF_DOCUMENT getDocumentPtr() { return doc; }
  int getPageCount();
  std::vector<PageSizeData> getAllPageSizes();
};
