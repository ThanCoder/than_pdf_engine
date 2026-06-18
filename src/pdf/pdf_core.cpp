#include "pdf_core.hpp"

#include <cstddef>

#include "fpdfview.h"
#include "pdf_page.hpp"

PdfCore::PdfCore() { FPDF_InitLibrary(); }

PdfCore::~PdfCore() {
  if (doc) {
    FPDF_CloseDocument(doc);
    doc = nullptr;
  }
  // FPDF_DestroyLibrary();
}

bool PdfCore::openFile(const std::string& path, const std::string& password) {
  doc = FPDF_LoadDocument(path.c_str(),
                          password.empty() ? nullptr : password.c_str());
  if (!doc) return false;

  return true;
}

bool PdfCore::openMemoryRaw(const unsigned char* dataBuffer, int dataSize,
                            const std::string& password) {
  doc = FPDF_LoadMemDocument(dataBuffer, dataSize,
                             password.empty() ? nullptr : password.c_str());

  if (!doc) return false;

  return true;
}

bool PdfCore::openMemory64Raw(const unsigned char* dataBuffer, int dataSize,
                              const std::string& password) {
  doc = FPDF_LoadMemDocument64(dataBuffer, static_cast<size_t>(dataSize),
                               password.empty() ? nullptr : password.c_str());

  if (!doc) return false;

  return true;
}

int PdfCore::getPageCount() {
  if (!doc) return -1;
  return FPDF_GetPageCount(doc);
}

PdfPage PdfCore::getPage(int pageIndex) {
  if (!doc) return PdfPage();
  auto page = FPDF_LoadPage(doc, pageIndex);
  if (!page) return PdfPage();
  return PdfPage{doc, page};
}
PdfPage* PdfCore::getPagePtr(int pageIndex) {
  if (!doc) return nullptr;
  auto page = FPDF_LoadPage(doc, pageIndex);
  if (!page) return nullptr;
  return new PdfPage{doc, page};
}

std::vector<PageCacheData> PdfCore::getPagesFromCacheRGBA(float zoomFactor,
                                                          int startIndex,
                                                          int endIndex) {
  std::vector<PageCacheData> resultPages;

  // စာမျက်နှာ ၃ သောင်းရှိတဲ့အထဲက တောင်းတဲ့ Range က ပတ်သက်မှုရှိမရှိ အရင်စစ်မယ်
  int totalPages = getPageCount();
  if (startIndex < 0) startIndex = 0;
  if (endIndex >= totalPages) endIndex = totalPages - 1;

  // တောင်းလိုက်တဲ့ ပမာဏအတိုင်း Vector Memory ကို ကြိုချဲ့ထားမယ်
  resultPages.reserve((endIndex - startIndex) + 1);

  // 🔄 Loop ပတ်ပြီး စာမျက်နှာတွေကို တစ်ခုချင်းစီ Render လုပ်မယ်
  for (int i = startIndex; i <= endIndex; ++i) {
    auto page = getPage(i);

    // ၃။ ဒေတာတွေကို ဆွဲထုတ်ပြီး structure ထဲ ထည့်မယ်
    PageCacheData cachedPage;
    cachedPage.pageIndex = i;
    cachedPage.width = page.getRenderWith(zoomFactor);
    cachedPage.height = page.getRenderHeight(zoomFactor);
    // quality 85 နဲ့ JPEG အဖြစ် တန်းပြောင်းခိုင်းလိုက်တာပါ
    cachedPage.rgbaData = page.renderToRGBA(zoomFactor);

    // ၄။ ရလဒ် Vector ထဲကို ထည့်မယ်
    resultPages.push_back(std::move(cachedPage));

    // Loop အဆုံးမှာ PdfPage ရဲ့ Destructor က Page ကို Auto ပြန်ပိတ်ပေးသွားပါလိမ့်မယ်
  }

  // ၅။ ရလာတဲ့ စာမျက်နှာ ၁၀ ခုစာ vector ကြီးကို Dart ဘက်ကို တန်းပြီး Return ပြန်ပေးလိုက်ပြီ!
  return resultPages;
}

std::vector<PageSizeData> PdfCore::getAllPageSizes() {
  std::vector<PageSizeData> sizes;
  if (!doc) return sizes;

  int totalPages = getPageCount();  // မူရင်း getPageCount() ကို ပြန်ခေါ်သုံးတာပါ
  sizes.reserve(totalPages);  // စာမျက်နှာ ၃ သောင်းစာအတွက် Vector Memory ကြိုချဲ့ထားမယ်

  for (int i = 0; i < totalPages; ++i) {
    FS_SIZEF sizeF;

    // 💡 Page တစ်ခုချင်းစီကို Load လုပ်စရာမလိုဘဲ Index အလိုက် Size ကို တိုက်ရိုက် လှမ်းတောင်းခြင်း
    if (FPDF_GetPageSizeByIndexF(doc, i, &sizeF)) {
      sizes.push_back({sizeF.width, sizeF.height});
    } else {
      // တစ်ခုခုလွဲချော်ခဲ့ရင် အမှားမခံဘဲ Default A4 Standard Size (Point အတိုင်းအတာ)
      // ထည့်ပေးထားမယ်
      sizes.push_back({612.0f, 792.0f});
    }
  }

  return sizes;
}