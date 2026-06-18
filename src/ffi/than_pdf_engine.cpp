#include "than_pdf_engine.h"

#include <cstdint>
#include <cstring>
#include <vector>

#include "fpdfview.h"
#include "pdf_core.hpp"
#include "pdf_page.hpp"

int sum_ffi(int a, int b) { return a + b; }

//  PdfCore();
void* pdf_core_create() { return new PdfCore(); }
// FPDF_DestroyLibrary
void pdfium_destroy() { FPDF_DestroyLibrary(); }

void pdf_core_destroy(void* pdf_core_ptr) {
  auto pdf = reinterpret_cast<PdfCore*>(pdf_core_ptr);
  if (pdf == nullptr) return;
  delete pdf;
}
// bool openFile(const std::string& path, const std::string& password = "");
bool pdf_core_openFile(void* pdf_core_ptr, const char* path, const char*,
                       const char* password) {
  auto pdf = reinterpret_cast<PdfCore*>(pdf_core_ptr);
  if (pdf == nullptr) return false;
  pdf->openFile(path, password);
  return true;
}
// bool openMemoryRaw(const unsigned char* dataBuffer, int dataSize,
//                    const std::string& password = "");
bool openMemoryRaw(void* pdf_core_ptr, const unsigned char* dataBuffer,
                   int dataSize, const char* password) {
  auto pdf = reinterpret_cast<PdfCore*>(pdf_core_ptr);
  if (pdf == nullptr) return false;
  pdf->openMemoryRaw(dataBuffer, dataSize);
  return true;
}

// bool openMemory64Raw(const unsigned char* dataBuffer, int dataSize,
//                      const std::string& password = "");
bool openMemory64Raw(void* pdf_core_ptr, const unsigned char* dataBuffer,
                     int dataSize, const char* password) {
  auto pdf = reinterpret_cast<PdfCore*>(pdf_core_ptr);
  if (pdf == nullptr) return false;
  pdf->openMemoryRaw(dataBuffer, dataSize);
  return true;
}

// int getPageCount();
int pdf_core_getPageCount(void* pdf_core_ptr) {
  auto pdf = reinterpret_cast<PdfCore*>(pdf_core_ptr);
  if (pdf == nullptr) return 0;
  return pdf->getPageCount();
}
// std::vector<PageSizeData> getAllPageSizes();
Page_Size_Data* pdf_core_getAllPageSizes(void* pdf_core_ptr) {
  auto pdf = reinterpret_cast<PdfCore*>(pdf_core_ptr);
  if (pdf == nullptr) return nullptr;

  // ၁။ C++ Vector ဒေတာကို လှမ်းယူမယ်
  std::vector<PageSizeData> cppSizes = pdf->getAllPageSizes();
  if (cppSizes.empty()) return nullptr;

  // ၂။ Dart ဘက်က ဖတ်လို့ရအောင် C-style Heap Memory ပေါ်မှာ Array အသစ် ဆောက်မယ်
  // (စာမျက်နှာ ၃ သောင်းစာအတွက် Memory Block တစ်ခုတည်း ကြိုတောင်းလိုက်တာပါ)
  Page_Size_Data* cSizes = new Page_Size_Data[cppSizes.size()];

  // ၃။ ဒေတာတွေကို C Structure ထဲ ကူးထည့်ခြင်း
  for (size_t i = 0; i < cppSizes.size(); ++i) {
    cSizes[i].width = cppSizes[i].width;
    cSizes[i].height = cppSizes[i].height;
  }

  // ၄။ အဲဒီ Array ရဲ့ အစဦးဆုံး Pointer ကို Dart FFI ဆီ လွှဲပေးလိုက်မယ်
  return cSizes;
}
// std::vector<PageCacheData> getPagesFromCacheRGBA(float zoomFactor,int
// startIndex, int endIndex);
Page_Cache_Data* pdf_core_getPagesFromCacheRGBA(void* pdf_core_ptr,
                                                float zoomFactor,
                                                int startIndex, int endIndex,
                                                int* genCacheCount) {
  auto pdf = reinterpret_cast<PdfCore*>(pdf_core_ptr);
  if (pdf == nullptr) return nullptr;
  auto data = pdf->getPagesFromCacheRGBA(zoomFactor, startIndex, endIndex);
  if (data.empty()) return nullptr;
  *genCacheCount = data.size();

  auto pcSize = new Page_Cache_Data[data.size()];

  for (int i = 0; i < data.size(); i++) {
    pcSize[i].width = data[i].width;
    pcSize[i].height = data[i].height;
    pcSize[i].pageIndex = data[i].pageIndex;
    // data
    auto val = data[i].rgbaData;
    pcSize[i].dataLength = val.size();

    pcSize[i].rgbaData = new uint8_t[val.size()];
    // ကူးမယ်
    std::memcpy(pcSize[i].rgbaData, val.data(), val.size());
  }

  return pcSize;
}

void pdf_core_free_CacheRGBAData(Page_Cache_Data* page_cache_data_ptr,
                                 int genCacheCount) {
  if (page_cache_data_ptr == nullptr) return;
  for (int i = 0; i < genCacheCount; i++) {
    if (page_cache_data_ptr[i].rgbaData != nullptr) {
      delete page_cache_data_ptr[i].rgbaData;
    }
  }
  delete[] page_cache_data_ptr;
}

// PdfPage getPage(int pageIndex);
void* pdf_core_getPage(void* pdf_core_ptr, int pageIndex) {
  auto pdf = reinterpret_cast<PdfCore*>(pdf_core_ptr);
  if (pdf == nullptr) return nullptr;

  return pdf->getPagePtr(pageIndex);
}