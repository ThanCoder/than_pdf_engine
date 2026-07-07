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

// FPDF_InitLibrary
void pdfium_init();

// FPDF_DestroyLibrary()
void pdfium_destroy();

//*******************PDF Core && PDF Page************************ */

typedef struct {
  float width;
  float height;
} Page_Size_Data;

typedef struct pdf_core_s* pdf_core_t;

//  PdfCore();
pdf_core_t pdf_core_create();

// ~PdfCore();
void pdf_core_destroy(pdf_core_t pdf_core_ptr);

// bool openFile(const std::string& path, const std::string& password = "");
bool pdf_core_openFile(pdf_core_t pdf_core_ptr, const char* path,
                       const char* password);
// bool openMemoryRaw(const unsigned char* dataBuffer, int dataSize,
//                    const std::string& password = "");
bool pdf_core_openMemoryRaw(pdf_core_t pdf_core_ptr,
                            const unsigned char* buffer, int buffer_Size,
                            const char* password);

// bool openMemory64Raw(const unsigned char* dataBuffer, int dataSize,
//                      const std::string& password = "");
bool pdf_core_openMemory64Raw(pdf_core_t pdf_core_ptr,
                              const unsigned char* buffer, int buffer_Size,
                              const char* password);

bool pdf_core_fileOpened(pdf_core_t pdf_core_ptr);

// int getPageCount();
int pdf_core_getPageCount(pdf_core_t pdf_core_ptr);

typedef struct page_size_data_s* page_size_data_t;

// std::vector<PageSizeData> getAllPageSizes();
// return -> `page_size_data_ptr`
page_size_data_t pdf_core_getAllPageSizes(pdf_core_t pdf_core_ptr,
                                          int* out_count_ptr);
// free -> `pdf_core_getAllPageSizes`
void pdf_core_free_getAllPageSizes(page_size_data_t page_size_data_ptr);

//-------------------PDF Page-----------------------
typedef struct pdf_page_s* pdf_page_t;
// return -> `pdf_page_ptr*`
pdf_page_t pdf_page_create(pdf_core_t pdf_core_ptr, int page_index);
//  ~PdfPage();
void pdf_page_destroy(pdf_page_t pdf_page_ptr);
// core opened
//
// page opened
bool pdf_page_isVaild(pdf_page_t pdf_page_ptr);

double pdf_page_getWidth(pdf_page_t pdf_page_ptr);
double pdf_page_getHeight(pdf_page_t pdf_page_ptr);

double pdf_page_getWidthF(pdf_page_t pdf_page_ptr);
double pdf_page_getHeightF(pdf_page_t pdf_page_ptr);

bool pdf_page_saveAsPngWH(pdf_page_t pdf_page_ptr, const char* out_path,
                          int width, int height);
bool pdf_page_saveAsJpgWH(pdf_page_t pdf_page_ptr, const char* out_path,
                          int width, int height, int quality);

unsigned char* pdf_page_renderToJpegWH(pdf_page_t pdf_page_ptr, int* data_size,
                                       int width, int height, int quality);
void pdf_page_free_renderToJpegWH(unsigned char* render_jpg_buff);

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