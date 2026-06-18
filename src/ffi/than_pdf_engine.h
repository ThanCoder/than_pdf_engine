#include <stdint.h>
#include <stdlib.h>

#include <cstdint>

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

//  PdfCore();
void* pdf_core_create();

// ~PdfCore();
void pdf_core_destroy(void* pdf_core_ptr);
// bool openFile(const std::string& path, const std::string& password = "");
bool pdf_core_openFile(void* pdf_core_ptr, const char* path, const char*,
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
// std::vector<PageCacheData> getPagesFromCacheRGBA(float zoomFactor,int
// startIndex, int endIndex);
Page_Cache_Data* pdf_core_getPagesFromCacheRGBA(void* pdf_core_ptr,
                                                float zoomFactor,
                                                int startIndex, int endIndex,

                                                int* genCacheCount);
// need to free
void pdf_core_free_CacheRGBAData(Page_Cache_Data* page_cache_data_ptr,
                                 int genCacheCount);
// PdfPage getPage(int pageIndex);
//
// return `pdf_page_ptr`
void* pdf_core_getPage(void* pdf_core_ptr, int pageIndex);

//-------------------PDF Page-----------------------

// PdfPage(FPDF_DOCUMENT doc = nullptr, FPDF_PAGE page =
// nullptr);
void* pdf_page_create(void* document, void* page);
//  ~PdfPage();
void pdf_page_destroy(void* pdf_page_ptr);

// std::uint8_t* getBitmapSourcePtr(float zoomFactor);
uint8_t* pdf_page_getBitmapSourcePtr(void* pdf_page_ptr, float zoomFactor);
// std::vector<uint8_t> renderToRGBA(float zoomFactor);
uint8_t* pdf_page_renderToRGBA(void* pdf_page_ptr, float zoomFactor);
// std::vector<uint8_t> renderToJpeg(float zoomFactor, int quality = 90);
uint8_t* pdf_page_renderToJpeg(void* pdf_page_ptr, float zoomFactor,
                               int quality, int* out_size);
// free render
void pdf_page_free_render_data(void* pdf_page_ptr, uint8_t* render_data_ptr);
// bool saveAsPng(const std::string& outPath, float zoomFactor);
bool pdf_page_saveAsPng(void* pdf_page_ptr, const char* outPath,
                        float zoomFactor);
// bool saveAsJpg(const std::string& outPath, float zoomFactor, int quality
// =90);
bool pdf_page_saveAsJpg(void* pdf_page_ptr, const char* outPath,
                        float zoomFactor, int quality);

// int getRenderWith(float zoomFactor)
int getRenderWith(void* pdf_page_ptr, float zoomFactor);
// int getRenderHeight(float zoomFactor)
int getRenderHeight(void* pdf_page_ptr, float zoomFactor);

//******************************************* */

#ifdef __cplusplus
}
#endif