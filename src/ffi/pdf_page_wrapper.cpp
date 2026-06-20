#include <cstdint>
#include <cstring>

#include "pdf_page.hpp"
#include "than_pdf_engine.h"

//  ~PdfPage();
void pdf_page_destroy(void* pdf_page_ptr) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (page == nullptr) return;
  delete page;
}

// std::uint8_t* getBitmapSourcePtr(float zoomFactor);
uint8_t* pdf_page_getBitmapSourcePtr(void* pdf_page_ptr, int targetWidth,
                                     int targetHeight) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (page == nullptr) return nullptr;
  return page->getBitmapSourcePtr(targetWidth, targetHeight);
}

// free render data
void pdf_page_free_render_data(uint8_t* render_data_ptr) {
  if (render_data_ptr == nullptr) return;
  delete[] render_data_ptr;
}

// std::vector<uint8_t> renderToRGBAWithDeviceWidth(int deviceWidth,float
// zoomFactor);
uint8_t* pdf_page_renderToRGBAWithDeviceWidth(void* pdf_page_ptr,
                                              int* bufferSize, int deviceWidth,
                                              float targetHeight) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (page == nullptr) return nullptr;
  auto vec = page->renderToRGBAWithDeviceWidth(deviceWidth, targetHeight);
  if (vec.empty()) return nullptr;

  *bufferSize = vec.size();

  auto buff = new uint8_t[vec.size()];
  std::memcpy(buff, vec.data(), vec.size());

  return buff;
}
// double getOriginalWidth();
float pdf_page_getOriginalWidth(void* pdf_page_ptr) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (page == nullptr) return 0;
  return page->getOriginalWidth();
}
// double getOriginalHeight();
float pdf_page_getOriginalHeight(void* pdf_page_ptr) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (page == nullptr) return 0;
  return page->getOriginalHeight();
}

uint8_t* pdf_page_renderToJpegWH(void* pdf_page_ptr, int* bufferSize, int width,
                                 int height, int quality) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (page == nullptr) return nullptr;
  auto vec = page->renderToJpegWH(width, height, quality);
  if (vec.empty()) return nullptr;

  *bufferSize = vec.size();

  auto buff = new uint8_t[vec.size()];
  std::memcpy(buff, vec.data(), vec.size());

  return buff;
}

bool pdf_page_saveAsPngWH(void* pdf_page_ptr, const char* outPath, int width,
                          int height) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (page == nullptr) return false;

  return page->saveAsJpgWH(outPath, width, height);
}
bool pdf_page_saveAsJpgWH(void* pdf_page_ptr, const char* outPath, int width,
                          int height, int quality) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (page == nullptr) return false;
  return page->saveAsJpgWH(outPath, width, height, quality);
}