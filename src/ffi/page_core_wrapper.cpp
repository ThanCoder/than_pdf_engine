#include <cstring>
#include <vector>

#include "ffi_wrapper.h"
#include "pdf_core.hpp"

pdf_core_t pdf_core_create() {
  return reinterpret_cast<pdf_core_t>(new PdfCore());
}

// ~PdfCore();
void pdf_core_destroy(pdf_core_t pdf_core_ptr) {
  auto core = reinterpret_cast<PdfCore*>(pdf_core_ptr);
  if (!core) return;
  delete core;
}

// bool openFile(const std::string& path, const std::string& password = "");
bool pdf_core_openFile(pdf_core_t pdf_core_ptr, const char* path,
                       const char* password) {
  auto core = reinterpret_cast<PdfCore*>(pdf_core_ptr);
  if (!core) return false;
  return core->openFile(path, password == nullptr ? "" : password);
}

// bool openMemoryRaw(const unsigned char* dataBuffer, int dataSize,
//                    const std::string& password = "");
bool pdf_core_openMemoryRaw(pdf_core_t pdf_core_ptr,
                            const unsigned char* buffer, int buffer_Size,
                            const char* password) {
  auto core = reinterpret_cast<PdfCore*>(pdf_core_ptr);
  if (!core) return false;
  return core->openMemoryRaw(buffer, buffer_Size,
                             password == nullptr ? "" : password);
}

// bool openMemory64Raw(const unsigned char* dataBuffer, int dataSize,
//                      const std::string& password = "");
bool pdf_core_openMemory64Raw(pdf_core_t pdf_core_ptr,
                              const unsigned char* buffer, int buffer_Size,
                              const char* password) {
  auto core = reinterpret_cast<PdfCore*>(pdf_core_ptr);
  if (!core) return false;
  return core->openMemory64Raw(buffer, buffer_Size,
                               password == nullptr ? "" : password);
}

bool pdf_core_fileOpened(pdf_core_t pdf_core_ptr) {
  auto core = reinterpret_cast<PdfCore*>(pdf_core_ptr);
  if (!core) return false;
  return core->fileOpened();
}

// int getPageCount();
int pdf_core_getPageCount(pdf_core_t pdf_core_ptr) {
  auto core = reinterpret_cast<PdfCore*>(pdf_core_ptr);
  if (!core) return 0;
  return core->getPageCount();
}
// std::vector<PageSizeData> getAllPageSizes();
// return -> `page_size_data_ptr`
page_size_data_t pdf_core_getAllPageSizes(pdf_core_t pdf_core_ptr,
                                          int* out_count_ptr) {
  auto core = reinterpret_cast<PdfCore*>(pdf_core_ptr);
  if (!core || !out_count_ptr) {
    return nullptr;
  }

  *out_count_ptr = 0;

  // ၁။ C++ Vector ဒေတာကို လှမ်းယူမယ်
  std::vector<PageSizeData> cppSizes = core->getAllPageSizes();
  if (cppSizes.empty()) {
    *out_count_ptr = 0;
    return nullptr;
  }

  // ၂။ Dart ဘက်က ဖတ်လို့ရအောင် C-style Heap Memory ပေါ်မှာ Array အသစ် ဆောက်မယ်
  // (စာမျက်နှာ ၃ သောင်းစာအတွက် Memory Block တစ်ခုတည်း ကြိုတောင်းလိုက်တာပါ)
  Page_Size_Data* cSizes = new Page_Size_Data[cppSizes.size()];

  // count ထည့်
  *out_count_ptr = static_cast<int>(cppSizes.size());

  // ၃။ ဒေတာတွေကို C Structure ထဲ ကူးထည့်ခြင်း
  for (size_t i = 0; i < cppSizes.size(); ++i) {
    cSizes[i].width = cppSizes[i].width;
    cSizes[i].height = cppSizes[i].height;
  }
  return reinterpret_cast<page_size_data_t>(cSizes);
}

void pdf_core_free_getAllPageSizes(page_size_data_t page_size_data_ptr) {
  auto data = reinterpret_cast<Page_Size_Data*>(page_size_data_ptr);
  if (!data) return;
  delete[] data;
}
