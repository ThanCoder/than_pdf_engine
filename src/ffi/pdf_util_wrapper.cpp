#include "ffi_wrapper.h"
#include "pdf_core.hpp"
#include "pdf_page.hpp"

bool pdf_util_saveJpgWithIndex(const char* pdf_path, const char* password,
                               const char* out_path, int page_index, int width,
                               int height, int quality) {
  PdfCore core;
  if (!core.openFile(pdf_path, password == nullptr ? "" : password)) {
    return false;
  }
  PdfPage page{&core, page_index};
  if (!page.saveAsJpgWH(out_path, width, height, quality)) {
    return false;
  }

  return true;
}

bool pdf_util_savePngWithIndex(const char* pdf_path, const char* password,
                               const char* out_path, int page_index, int width,
                               int height) {
  PdfCore core;
  if (!core.openFile(pdf_path, password == nullptr ? "" : password)) {
    return false;
  }
  PdfPage page{&core, page_index};
  if (!page.saveAsPngWH(out_path, width, height)) {
    return false;
  }

  return true;
}