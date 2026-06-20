#include "pdf_core.hpp"
#include "than_pdf_engine.h"

bool pdf_util_saveJpgWithIndex(const char* pdf_path, const char* password,
                               const char* out_path, int page_index, int width,
                               int height, int quality) {
  PdfCore core;
  if (!core.openFile(pdf_path, password == nullptr ? "" : password)) {
    return false;
  }
  auto page = core.getPage(page_index);
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
  auto page = core.getPage(page_index);
  if (!page.saveAsPngWH(out_path, width, height)) {
    return false;
  }

  return true;
}