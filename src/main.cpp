#include <cstdint>
#include <fstream>
#include <string>
#include <vector>
extern "C" {
#include "fpdfview.h"
}

#include "pdf_core.hpp"
#include "pdf_page.hpp"
#include <iostream>

void writeFile(std::vector<uint8_t> &data, const std::string path) {
  if (data.empty()) {
    std::cout << "data is empty!\n";
    return;
  }

  std::ofstream f(path, std::ios::out | std::ios::binary);
  f.write(reinterpret_cast<const char *>(data.data()), data.size());

  f.close();
}

int main() {
  FPDF_InitLibrary();

  auto core = new PdfCore();
  core->openFile("/home/thancoder/Documents/test.pdf");

  PdfPage page{core, 1};

  // page.saveAsPngWH("../page.png",0,0);

  auto png = page.renderToPngWH(0, 0);
  auto jpg = page.renderToJpegWH(0, 0);

  writeFile(png, "../page-v.png");
  writeFile(jpg, "../page-v.jpg");

  return 0;
}