#include "pdf_core.hpp"

#include <cstddef>
#include <filesystem>
#include <iostream>

#include "fpdfview.h"

PdfCore::~PdfCore() {
  if (doc) {
    FPDF_CloseDocument(doc);
    doc = nullptr;
  }
}

bool PdfCore::openFile(const std::string &path, const std::string &password) {
  if (!std::filesystem::exists(path)) {
    std::cerr << "[PdfCore::openFile]: `Path Not Found!` Error\n";
    return false;
  }
  doc = FPDF_LoadDocument(path.c_str(),
                          password.empty() ? nullptr : password.c_str());
  if (!doc) {
    std::cerr << "[PdfCore::openFile]: `FPDF_LoadDocument` Error\n";
    return false;
  }
  isFileOpened = true;
  return true;
}

bool PdfCore::openMemoryRaw(const unsigned char *dataBuffer, int dataSize,
                            const std::string &password) {
  doc = FPDF_LoadMemDocument(dataBuffer, dataSize,
                             password.empty() ? nullptr : password.c_str());

  if (!doc) {
    std::cerr << "[PdfCore::openFile]: `FPDF_LoadMemDocument` Error\n";
    return false;
  }

  return true;
}

bool PdfCore::openMemory64Raw(const unsigned char *dataBuffer, int dataSize,
                              const std::string &password) {
  doc = FPDF_LoadMemDocument64(dataBuffer, static_cast<size_t>(dataSize),
                               password.empty() ? nullptr : password.c_str());

  if (!doc) {
    std::cerr << "[PdfCore::openFile]: `FPDF_LoadMemDocument64` Error\n";
    return false;
  }

  return true;
}

int PdfCore::getPageCount() {
  if (!doc)
    return -1;
  return FPDF_GetPageCount(doc);
}

std::vector<PageSizeData> PdfCore::getAllPageSizes() {
  std::vector<PageSizeData> sizes;
  if (!doc)
    return sizes;

  int totalPages = getPageCount();
  sizes.reserve(totalPages);

  for (int i = 0; i < totalPages; ++i) {
    FS_SIZEF sizeF = {0.0f, 0.0f};

    // Size ရရင် ရသလို ထည့်မယ်၊ မရရင် 0.0f, 0.0f ပဲ ဝင်သွားမယ်
    FPDF_GetPageSizeByIndexF(doc, i, &sizeF);
    sizes.push_back({sizeF.width, sizeF.height});
  }

  return sizes;
}

// std::vector<PageSizeData> PdfCore::getAllPageSizes() {
//   std::vector<PageSizeData> sizes;
//   if (!doc)
//     return sizes;

//   int totalPages = getPageCount(); // မူရင်း getPageCount() ကို ပြန်ခေါ်သုံးတာပါ
//   sizes.reserve(totalPages); // စာမျက်နှာ ၃ သောင်းစာအတွက် Vector Memory ကြိုချဲ့ထားမယ်

//   for (int i = 0; i < totalPages; ++i) {
//     FS_SIZEF sizeF;

//     // 💡 Page တစ်ခုချင်းစီကို Load လုပ်စရာမလိုဘဲ Index အလိုက် Size ကို တိုက်ရိုက် လှမ်းတောင်းခြင်း
//     if (FPDF_GetPageSizeByIndexF(doc, i, &sizeF)) {
//       sizes.push_back({sizeF.width, sizeF.height});
//     } else {
//       // တစ်ခုခုလွဲချော်ခဲ့ရင် အမှားမခံဘဲ Default A4 Standard Size (Point အတိုင်းအတာ)
//       // ထည့်ပေးထားမယ်
//       sizes.push_back({612.0f, 792.0f});
//     }
//   }

//   return sizes;
// }