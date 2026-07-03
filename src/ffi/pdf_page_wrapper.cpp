#include <cstddef>
#include <cstdlib>
#include <cstring>

#include "ffi_wrapper.h"
#include "pdf_core.hpp"
#include "pdf_page.hpp"

void* pdf_page_create(void* pdf_core_ptr, int page_index) {
  auto core = reinterpret_cast<PdfCore*>(pdf_core_ptr);
  if (!core) return nullptr;
  return new PdfPage{core, page_index};
}
//  ~PdfPage();
void pdf_page_destroy(void* pdf_page_ptr) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (!page) return;
  delete page;
}

bool pdf_page_isVaild(void* pdf_page_ptr) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (!page) return false;
  return page->isValid();
}

double pdf_page_getWidth(void* pdf_page_ptr) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (!page) return 0;
  return page->getWidth();
}
double pdf_page_getHeight(void* pdf_page_ptr) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (!page) return 0;
  return page->getHeight();
}

double pdf_page_getWidthF(void* pdf_page_ptr) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (!page) return 0;
  return page->getWidthF();
}
double pdf_page_getHeightF(void* pdf_page_ptr) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (!page) return 0;
  return page->getHeightF();
}

bool pdf_page_saveAsPngWH(void* pdf_page_ptr, const char* out_path, int width,
                          int height) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (!page) return false;
  return page->saveAsPngWH(out_path, width, height);
}
bool pdf_page_saveAsJpgWH(void* pdf_page_ptr, const char* out_path, int width,
                          int height, int quality) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (!page) return false;
  return page->saveAsJpgWH(out_path, width, height, quality);
}

unsigned char* pdf_page_renderToJpegWH(void* pdf_page_ptr, int* data_size,
                                       int width, int height, int quality) {
  auto page = reinterpret_cast<PdfPage*>(pdf_page_ptr);
  if (!page || !data_size) return nullptr;

  auto data = page->renderToJpegWH(width, height, quality);
  if (data.empty()) {
    *data_size = 0;
    return nullptr;
  }
  size_t dataSize = data.size();
  *data_size = static_cast<int>(dataSize);

  auto buff = static_cast<unsigned char*>(malloc(dataSize));
  if (!buff) return nullptr;

  std::memcpy(buff, data.data(), dataSize);
  return buff;
}

void pdf_page_free_renderToJpegWH(unsigned char* render_jpg_buff) {
  if (!render_jpg_buff) return;
  free(render_jpg_buff);
}