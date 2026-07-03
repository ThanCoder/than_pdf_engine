#include "pdf_page.hpp"

#include <fstream>
#include <iostream>
#include <stdexcept>

#include "fpdfview.h"
#include "pdf_core.hpp"

PdfPage::PdfPage(PdfCore* core, int pageIndex) : core(core) {
  if (!core) {
    std::cerr << "`PdfCore` is nullptr \n";
    return;
  }
  page = FPDF_LoadPage(core->getDocumentPtr(), pageIndex);
  if (!page) {
    std::cerr << "`FPDF_LoadPage` is nullptr \n";
    return;
  }
  width = FPDF_GetPageWidth(page);
  height = FPDF_GetPageHeight(page);
  width_f = FPDF_GetPageWidthF(page);
  height_f = FPDF_GetPageHeightF(page);
}

PdfPage::~PdfPage() {
  if (page) {
    FPDF_ClosePage(page);
    page = nullptr;
  }
  if (current_bitmap) {
    FPDFBitmap_Destroy(current_bitmap);
    current_bitmap = nullptr;
  }
}

std::uint8_t* PdfPage::getBitmapSourcePtr(int targetWidth, int targetHeight) {
  if (!isValid()) return nullptr;
  // နဂိုရှိပြီးသား bitmap ကို ဖျက်မယ်
  if (current_bitmap) {
    FPDFBitmap_Destroy(current_bitmap);
    current_bitmap = nullptr;
  }

  // အပြင်က ပေးလိုက်တဲ့ targetWidth, targetHeight အတိုင်း တိုက်ရိုက်ဆောက်မယ်
  current_bitmap = FPDFBitmap_Create(targetWidth, targetHeight, 1);
  if (!current_bitmap) return nullptr;

  FPDFBitmap_FillRect(current_bitmap, 0, 0, targetWidth, targetHeight,
                      0xFFFFFFFF);

  int renderFlags = FPDF_LCD_TEXT | FPDF_RENDER_FORCEHALFTONE | FPDF_ANNOT;

  FPDF_RenderPageBitmap(current_bitmap, page, 0, 0, targetWidth, targetHeight,
                        0, renderFlags);

  return static_cast<uint8_t*>(FPDFBitmap_GetBuffer(current_bitmap));
}

void stbi_write_to_vector(void* context, void* data, int size) {
  auto* vec = static_cast<std::vector<uint8_t>*>(context);
  auto* bytes = static_cast<const uint8_t*>(data);

  // insert သုံးရင် လက်ရှိ vector အဆုံးမှာ memory reallocation ကို
  // ပိုပြီး ထိရောက်အောင် သူဘာသာ စီမံသွားမှာဖြစ်ပါတယ်
  vec->insert(vec->end(), bytes, bytes + size);
}

std::vector<uint8_t> PdfPage::renderToRGBAWithDeviceWidth(int targetWidth,
                                                          int targetHeight) {
  std::vector<uint8_t> rgba_buffer;
  if (!isValid()) return rgba_buffer;
  if (!page) return rgba_buffer;

  // ၁။ PDFium Bitmap ကို ဆောက်ခြင်း (1 = FPDFBitmap_BGRA)
  FPDF_BITMAP bitmap = FPDFBitmap_Create(targetWidth, targetHeight, 1);
  if (!bitmap) return rgba_buffer;

  // Background ကို အဖြူရောင် Clear လုပ်ပေးခြင်း
  FPDFBitmap_FillRect(bitmap, 0, 0, targetWidth, targetHeight, 0xFFFFFFFF);

  // PDF စာမျက်နှာကို Bitmap ပေါ် ရင်ဒါဆွဲခိုင်းခြင်း
  FPDF_RenderPageBitmap(bitmap, page, 0, 0, targetWidth, targetHeight, 0, 0);

  std::uint8_t* source_buffer =
      static_cast<std::uint8_t*>(FPDFBitmap_GetBuffer(bitmap));
  int stride = FPDFBitmap_GetStride(bitmap);

  // Safe Check: Memory size overflow မဖြစ်အောင် ကာကွယ်ခြင်း
  size_t required_size =
      static_cast<size_t>(targetWidth) * static_cast<size_t>(targetHeight) * 4;
  try {
    rgba_buffer.resize(required_size);
  } catch (const std::bad_alloc& e) {  // length_error ထက် memory allocation
                                       // failure အတွက် bad_alloc က ပိုမှန်ပါတယ်
    FPDFBitmap_Destroy(bitmap);
    return rgba_buffer;
  }

  // ၂။ Loop ပတ်ပြီး BGRA ကနေ RGBA ပြောင်းလဲခြင်း Logic
  for (int y = 0; y < targetHeight; ++y) {
    uint8_t* src_row = source_buffer + (y * stride);
    uint8_t* dst_row = rgba_buffer.data() + (y * targetWidth * 4);

    for (int x = 0; x < targetWidth; ++x) {
      int src_idx = x * 4;
      int dst_idx = x * 4;

      // Safe Check: targetWidth အတွင်းပဲမို့ စိတ်ချရပါတယ် (stride ထက် ကျော်မကျော် စစ်တာကို
      // ပိုရှင်းအောင် လုပ်ထားပါတယ်)
      if (src_idx + 3 < stride) {
        dst_row[dst_idx + 0] = src_row[src_idx + 2];  // R
        dst_row[dst_idx + 1] = src_row[src_idx + 1];  // G
        dst_row[dst_idx + 2] = src_row[src_idx + 0];  // B
        dst_row[dst_idx + 3] = src_row[src_idx + 3];  // A
      } else {
        dst_row[dst_idx + 0] = 255;
        dst_row[dst_idx + 1] = 255;
        dst_row[dst_idx + 2] = 255;
        dst_row[dst_idx + 3] = 255;
      }
    }
  }

  FPDFBitmap_Destroy(bitmap);
  return rgba_buffer;
}

std::vector<uint8_t> PdfPage::renderToJpegWH(int targetWidth, int targetHeight,
                                             int quality) {
  std::vector<uint8_t> outputJpegData;
  if (!isValid() || !page) return outputJpegData;

  // 0 ဖြစ်နေရင် original size သုံးမယ်
  if (targetWidth == 0) targetWidth = width;
  if (targetHeight == 0) targetHeight = height;

  // 💡 အရေးကြီးဆုံးအချက်: Render လုပ်တဲ့အချိန်မှာတင် target size ကို ထည့်ပါ
  // (သင်၏ renderToRGBAWithDeviceWidth function က target size လက်ခံနိုင်အောင်
  // ပြင်ထားရပါမယ်)
  auto rgba_data = renderToRGBAWithDeviceWidth(targetWidth, targetHeight);

  if (rgba_data.empty()) return outputJpegData;

  size_t total_pixels = static_cast<size_t>(targetWidth * targetHeight);

  // အကယ်၍ rgba_data.size() / 4 က total_pixels နဲ့ မကိုက်ရင် error တက်နိုင်ပါတယ်
  if (rgba_data.size() < total_pixels * 4) return outputJpegData;

  std::vector<uint8_t> rgb_data;
  rgb_data.resize(total_pixels * 3);  // reserve အစား resize သုံးပါ

  for (size_t i = 0; i < total_pixels; ++i) {
    size_t rgba_idx = i * 4;
    size_t rgb_idx = i * 3;
    rgb_data[rgb_idx] = rgba_data[rgba_idx];          // R
    rgb_data[rgb_idx + 1] = rgba_data[rgba_idx + 1];  // G
    rgb_data[rgb_idx + 2] = rgba_data[rgba_idx + 2];  // B
  }

  stbi_write_jpg_to_func(stbi_write_to_vector, &outputJpegData, targetWidth,
                         targetHeight, 3, rgb_data.data(), quality);

  return outputJpegData;
}

bool PdfPage::saveAsPngWH(const std::string& outPath, int targetWidth,
                          int targetHeight) {
  if (!isValid()) return false;
  if (targetWidth == 0) {
    targetWidth = width;
  }
  if (targetHeight == 0) {
    targetHeight = height;
  }
  // ၂။ RGBA data ကို ယူမယ်
  auto rgba_data = renderToRGBAWithDeviceWidth(targetWidth, targetHeight);
  if (rgba_data.empty()) return false;

  // 💡 ၃။ stride_in_bytes နေရာမှာ (targettargetWidth * 4) ကို ပြောင်းသုံးရပါမယ်
  int stride_in_bytes = targetWidth * 4;

  int success = stbi_write_png(outPath.c_str(), targetWidth, targetHeight, 4,
                               rgba_data.data(), stride_in_bytes);

  return success != 0;
}
// အကြံပြုချက်: ဤသို့ ပြင်ဆင်နိုင်သည်
bool PdfPage::saveAsJpgWH(const std::string& outPath, int targetWidth,
                          int targetHeight, int quality) {
  if (!page) return false;
  if (!isValid()) return false;
  auto buff = renderToJpegWH(targetWidth, targetHeight, quality);
  if (buff.empty()) return false;

  std::ofstream outFile(outPath);
  if (!outFile.is_open()) return false;

  outFile.write(reinterpret_cast<const char*>(buff.data()), buff.size());

  outFile.flush();
  outFile.close();
  return true;
}