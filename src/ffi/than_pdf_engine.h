#include <stdbool.h>  // 💡 [ဒီကောင်လေး ထပ်ဖြည့်ပေးပါ] bool ကို နားလည်စေရန်
#include <stdint.h>   // uint8_t ကို နားလည်စေရန်
#include <stdlib.h>

#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif
#ifdef __cplusplus
extern "C" {
#else
#endif
//*******************PDFium Lib************************ */

// FPDF_DestroyLibrary()
void pdfium_destroy();

//*******************PDF Core && PDF Page************************ */
typedef struct {
  int pageIndex;
  int width;
  int height;
  int dataLength;
  uint8_t* rgbaData;
} Page_Cache_Data;

typedef struct {
  float width;
  float height;
} Page_Size_Data;

// pdfium
void pdfium_init();

//  PdfCore();
void* pdf_core_create();

// ~PdfCore();
void pdf_core_destroy(void* pdf_core_ptr);
// bool openFile(const std::string& path, const std::string& password = "");
bool pdf_core_openFile(void* pdf_core_ptr, const char* path,
                       const char* password);
// bool openMemoryRaw(const unsigned char* dataBuffer, int dataSize,
//                    const std::string& password = "");
bool openMemoryRaw(void* pdf_core_ptr, const unsigned char* dataBuffer,
                   int dataSize, const char* password);

// bool openMemory64Raw(const unsigned char* dataBuffer, int dataSize,
//                      const std::string& password = "");
bool openMemory64Raw(void* pdf_core_ptr, const unsigned char* dataBuffer,
                     int dataSize, const char* password);

// int getPageCount();
int pdf_core_getPageCount(void* pdf_core_ptr);
// std::vector<PageSizeData> getAllPageSizes();
Page_Size_Data* pdf_core_getAllPageSizes(void* pdf_core_ptr);
void pdf_core_free_pageSizes(void* page_size_data_ptr);

// PdfPage getPage(int pageIndex);
//
// return `pdf_page_ptr`
void* pdf_core_getPage(void* pdf_core_ptr, int pageIndex);

//-------------------PDF Page-----------------------

//  ~PdfPage();
void pdf_page_destroy(void* pdf_page_ptr);

// std::uint8_t* getBitmapSourcePtr(float zoomFactor);
uint8_t* pdf_page_getBitmapSourcePtr(void* pdf_page_ptr, int targetWidth,
                                     int targetHeight);
// free render data
void pdf_page_free_render_data(uint8_t* render_data_ptr);

// std::vector<uint8_t> renderToRGBAWithDeviceWidth(int deviceWidth,float
// zoomFactor);
uint8_t* pdf_page_renderToRGBAWithDeviceWidth(void* pdf_page_ptr,
                                              int* bufferSize, int deviceWidth,
                                              float targetHeight);
// double getOriginalWidth();
float pdf_page_getOriginalWidth(void* pdf_page_ptr);
// double getOriginalHeight();
float pdf_page_getOriginalHeight(void* pdf_page_ptr);

uint8_t* pdf_page_renderToJpegWH(void* pdf_page_ptr, int* bufferSize, int width,
                                 int height, int quality);
bool pdf_page_saveAsPngWH(void* pdf_page_ptr, const char* outPath, int width,
                          int height);
bool pdf_page_saveAsJpgWH(void* pdf_page_ptr, const char* outPath, int width,
                          int height, int quality);

//********************PDF Util *********************** */
bool pdf_util_saveJpgWithIndex(const char* pdf_path, const char* password,
                               const char* out_path, int page_index, int width,
                               int height, int quality);
bool pdf_util_savePngWithIndex(const char* pdf_path, const char* password,
                               const char* out_path, int page_index, int width,
                               int height);

#ifdef __cplusplus
}
#endif