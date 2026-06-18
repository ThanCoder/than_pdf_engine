#include <cstdint>
#include <cstring>

#include "fpdfview.h"
#include "pdf_page.hpp"
#include "than_pdf_engine.h"

// static PdfPage* createPagePtrFromDom(FPDF_DOCUMENT dom, int pageIndex)
void* pdf_page_create_from_page_index(void* document, int pageIndex) {
  auto dom = reinterpret_cast<FPDF_DOCUMENT>(document);
  if (dom == nullptr) return nullptr;
  return PdfPage::createPagePtrFromDom(dom, pageIndex);
}
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
// std::vector<uint8_t> renderToRGBA(float zoomFactor);
uint8_t* pdf_page_renderToRGBA(void* pdf_page_ptr, int* bufferSize,
                               float zoomFactor) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (page == nullptr) return nullptr;
  auto vec = page->renderToRGBA(zoomFactor);
  if (vec.empty()) return nullptr;

  *bufferSize = vec.size();

  auto buff = new uint8_t[vec.size()];
  std::memcpy(buff, vec.data(), vec.size());

  return buff;
}
// std::vector<uint8_t> renderToJpeg(float zoomFactor, int quality = 90);
uint8_t* pdf_page_renderToJpeg(void* pdf_page_ptr, int* bufferSize,
                               int deviceWidth, float zoomFactor, int quality) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (page == nullptr) return nullptr;
  auto vec = page->renderToJpeg(deviceWidth, zoomFactor, quality);
  if (vec.empty()) return nullptr;

  *bufferSize = vec.size();

  auto buff = new uint8_t[vec.size()];
  std::memcpy(buff, vec.data(), vec.size());

  return buff;
}
// free render data
void pdf_page_free_render_data(uint8_t* render_data_ptr) {
  if (render_data_ptr == nullptr) return;
  delete[] render_data_ptr;
}
// bool saveAsPng(const std::string& outPath, float zoomFactor);
bool pdf_page_saveAsPng(void* pdf_page_ptr, const char* outPath,
                        float zoomFactor) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (page == nullptr) return false;
  return page->saveAsPng(outPath, zoomFactor);
}
// bool saveAsJpg(const std::string& outPath, float zoomFactor, int quality
// =90);
bool pdf_page_saveAsJpg(void* pdf_page_ptr, const char* outPath,
                        float zoomFactor, int quality) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (page == nullptr) return false;
  return page->saveAsJpg(outPath, zoomFactor, quality);
}

// int getRenderWith(float zoomFactor)
int pdf_page_getRenderWidth(void* pdf_page_ptr, float zoomFactor) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (page == nullptr) return 0;
  return page->getRenderWith(zoomFactor);
}
// int getRenderHeight(float zoomFactor)
int pdf_page_getRenderHeight(void* pdf_page_ptr, float zoomFactor) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (page == nullptr) return 0;
  return page->getRenderHeight(zoomFactor);
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