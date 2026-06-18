#include "pdf_page.hpp"

#include <stdexcept>

#include "fpdfview.h"

PdfPage::PdfPage(FPDF_DOCUMENT doc, FPDF_PAGE page) : doc(doc), page(page) {
  if (!page) return;
  width = FPDF_GetPageWidth(page);
  height = FPDF_GetPageHeight(page);
  width_f = static_cast<int>(FPDF_GetPageWidthF(page));
  height_f = static_cast<int>(FPDF_GetPageHeightF(page));
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

std::vector<uint8_t> PdfPage::renderToRGBA(float zoomFactor) {
  std::vector<uint8_t> rgba_buffer;

  if (!page) return rgba_buffer;

  int targetWidth = getRenderWith(zoomFactor);
  int targetHeight = getRenderHeight(zoomFactor);

  std::uint8_t* source_buffer = getBitmapSourcePtr(targetWidth, targetHeight);
  if (!source_buffer) return rgba_buffer;

  int stride = FPDFBitmap_GetStride(current_bitmap);
  rgba_buffer.resize(targetWidth * targetHeight * 4);

  for (int y = 0; y < targetHeight; ++y) {
    // 💡 Stride အတိုင်း Row pointer ကို တွက်ချက်တာ မှန်ကန်ပါတယ်
    uint8_t* src_row = source_buffer + (y * stride);
    uint8_t* dst_row = rgba_buffer.data() + (y * targetWidth * 4);

    for (int x = 0; x < targetWidth; ++x) {
      // 💡 ဒီနေရာမှာ x * 4 က stride ထက် ကျော်မသွားဖို့ လိုပါတယ်
      int src_x = x * 4;
      int dst_x = x * 4;

      // တကယ်လို့ stride ထဲမှာ data က ကွက်တိမရှိရင် targetWidth ထက် ကျော်ပြီး read မိနိုင်ခြေ ရှိ/မရှိ
      // စစ်ဆေးပါ
      if (src_x + 3 < stride) {
        dst_row[dst_x + 0] = src_row[src_x + 2];  // R
        dst_row[dst_x + 1] = src_row[src_x + 1];  // G
        dst_row[dst_x + 2] = src_row[src_x + 0];  // B
        dst_row[dst_x + 3] = src_row[src_x + 3];  // A
      }
    }
  }

  return rgba_buffer;
}

void stbi_write_to_vector(void* context, void* data, int size) {
  auto* vec = static_cast<std::vector<uint8_t>*>(context);
  auto* bytes = static_cast<const uint8_t*>(data);

  // insert သုံးရင် လက်ရှိ vector အဆုံးမှာ memory reallocation ကို
  // ပိုပြီး ထိရောက်အောင် သူဘာသာ စီမံသွားမှာဖြစ်ပါတယ်
  vec->insert(vec->end(), bytes, bytes + size);
}

std::vector<uint8_t> PdfPage::renderToJpeg(int deviceWidth, float zoomFactor,
                                           int quality) {
  std::vector<uint8_t> outputJpegData;
  if (!page) return outputJpegData;

  // ၁။ မူရင်း PDF ရဲ့ Width/Height အချိုးကို ရှာတယ်
  double origWidth = getOriginalWidth();
  double origHeight = getOriginalHeight();
  if (origWidth <= 0 || origHeight <= 0) return outputJpegData;  // Safety Check

  double aspectRatio = origHeight / origWidth;

  // ၂။ Target Size ကို တွက်ချက်ခြင်း
  int targetWidth = static_cast<int>(deviceWidth * zoomFactor);
  int targetHeight = static_cast<int>(targetWidth * aspectRatio);

  if (targetWidth <= 0 || targetHeight <= 0) return outputJpegData;

  // ၃။ Target Size အတိုင်း RGBA ထုတ်ယူခြင်း
  auto rgba_data = renderToRGBAWithDeviceWidth(targetWidth, targetHeight);
  if (rgba_data.empty()) return outputJpegData;

  // 💡 Safe Check: တကယ်ရလာတဲ့ Pixel အရေအတွက်ကိုပဲ အခြေခံပြီး တွက်ပါမယ်
  // (ဒါမှ Memory Crash ဖြစ်တာကို ကာကွယ်နိုင်မှာပါ)
  size_t total_pixels = rgba_data.size() / 4;

  // ၄။ RGBA မှ RGB သို့ စိတ်ချရစွာ ပြောင်းလဲခြင်း
  std::vector<uint8_t> rgb_data;
  try {
    rgb_data.reserve(total_pixels * 3);
  } catch (const std::length_error& e) {
    // Memory မဆံ့ရင် Crash မဖြစ်စေဘဲ ဒီမှာတင် ရပ်လိုက်မယ်
    return outputJpegData;
  }

  for (size_t i = 0; i < total_pixels; ++i) {
    size_t rgba_idx = i * 4;
    rgb_data.push_back(rgba_data[rgba_idx]);      // R
    rgb_data.push_back(rgba_data[rgba_idx + 1]);  // G
    rgb_data.push_back(rgba_data[rgba_idx + 2]);  // B
  }

  // ၅။ STB သို့ ကျွေးပြီး JPEG ပြောင်းခိုင်းမယ် 🎯
  // 💡 targetWidth နဲ့ targetHeight နေရာမှာ တကယ်ရလာတဲ့ pixel data နဲ့ ကိုက်ညီအောင် သုံးထားပါတယ်
  stbi_write_jpg_to_func(stbi_write_to_vector, &outputJpegData, targetWidth,
                         targetHeight, 3, rgb_data.data(), quality);

  return outputJpegData;
}

bool PdfPage::saveAsPng(const std::string& outPath, float zoomFactor) {
  // ၁။ target width နဲ့ height ကို အရင်တွက်မယ်
  int targetWidth = getRenderWith(zoomFactor);
  int targetHeight = getRenderHeight(zoomFactor);

  // ၂။ RGBA data ကို ယူမယ်
  auto rgba_data = renderToRGBA(zoomFactor);
  if (rgba_data.empty()) return false;

  // 💡 ၃။ stride_in_bytes နေရာမှာ (targetWidth * 4) ကို ပြောင်းသုံးရပါမယ်
  int stride_in_bytes = targetWidth * 4;

  int success = stbi_write_png(outPath.c_str(), targetWidth, targetHeight, 4,
                               rgba_data.data(), stride_in_bytes);

  return success != 0;
}

bool PdfPage::saveAsJpg(const std::string& outPath, float zoomFactor,
                        int quality) {
  // ၁။ target width နဲ့ height ကို အရင်တွက်မယ်
  int targetWidth = getRenderWith(zoomFactor);
  int targetHeight = getRenderHeight(zoomFactor);

  // ၂။ RGBA data ကို ယူမယ်
  auto rgba_data = renderToRGBA(zoomFactor);
  if (rgba_data.empty()) return false;

  // 💡 ၃။ stride_in_bytes နေရာမှာ (targetWidth * 4) ကို ပြောင်းသုံးရပါမယ်
  int stride_in_bytes = targetWidth * 4;

  int success = stbi_write_jpg(outPath.c_str(), targetWidth, targetHeight, 4,
                               rgba_data.data(), stride_in_bytes);

  return success != 0;
}

double PdfPage::getOriginalWidth() { return FPDF_GetPageWidth(page); }

double PdfPage::getOriginalHeight() { return FPDF_GetPageHeight(page); }

// 💡 မင်းရဲ့ အိုင်ဒီယာအတိုင်း Flutter ကပေးတဲ့ Target Width ပေါ်မူတည်ပြီး Height ကို တွက်ပေးမယ့်နေရာ
std::vector<uint8_t> PdfPage::renderToRGBAWithDeviceWidth(int targetWidth,
                                                          int targetHeight) {
  std::vector<uint8_t> rgba_buffer;
  if (!page || targetWidth <= 0 || targetHeight <= 0) return rgba_buffer;

  // ၁။ PDFium Bitmap ကို ဆောက်ခြင်း (1 = FPDFBitmap_BGRA)
  FPDF_BITMAP bitmap = FPDFBitmap_Create(targetWidth, targetHeight, 1);
  if (!bitmap) return rgba_buffer;  // Bitmap ဆောက်လို့မရရင် လှည့်ပြန်မယ်

  // Background ကို အဖြူရောင် Clear လုပ်ပေးခြင်း
  FPDFBitmap_FillRect(bitmap, 0, 0, targetWidth, targetHeight, 0xFFFFFFFF);

  // PDF စာမျက်နှာကို Bitmap ပေါ် ရင်ဒါဆွဲခိုင်းခြင်း
  FPDF_RenderPageBitmap(bitmap, page, 0, 0, targetWidth, targetHeight, 0, 0);

  std::uint8_t* source_buffer =
      static_cast<std::uint8_t*>(FPDFBitmap_GetBuffer(bitmap));
  int stride = FPDFBitmap_GetStride(bitmap);

  // 💡 Safe Check: Memory size overflow မဖြစ်အောင် အရင်ကာကွယ်မယ်
  size_t required_size =
      static_cast<size_t>(targetWidth) * static_cast<size_t>(targetHeight) * 4;
  try {
    rgba_buffer.resize(required_size);
  } catch (const std::length_error& e) {
    FPDFBitmap_Destroy(bitmap);  // Crash မဖြစ်ခင် bitmap ကို အရင်ဖျက်ပေးရမယ်
    return rgba_buffer;
  }

  // ၂။ Loop ပတ်ပြီး BGRA ကနေ RGBA ပြောင်းလဲခြင်း Logic 🎯
  for (int y = 0; y < targetHeight; ++y) {
    uint8_t* src_row = source_buffer + (y * stride);
    uint8_t* dst_row = rgba_buffer.data() + (y * targetWidth * 4);

    for (int x = 0; x < targetWidth; ++x) {
      int src_idx = x * 4;
      int dst_idx = x * 4;

      // 💡 SAFETY FIRST: သတ်မှတ်ထားတဲ့ stride ထက် ကျော်မသွားကြောင်း သေချာမှ ဖတ်မယ်
      if (src_idx + 3 < stride) {
        dst_row[dst_idx + 0] = src_row[src_idx + 2];  // R = B
        dst_row[dst_idx + 1] = src_row[src_idx + 1];  // G = G
        dst_row[dst_idx + 2] = src_row[src_idx + 0];  // B = R
        dst_row[dst_idx + 3] = src_row[src_idx + 3];  // A = A
      } else {
        // တကယ်လို့ stride ထက် ကျော်နေရင် Safe ဖြစ်အောင် Transparent သို့မဟုတ် အဖြူရောင်
        // ထည့်ပေးထားမယ်
        dst_row[dst_idx + 0] = 255;
        dst_row[dst_idx + 1] = 255;
        dst_row[dst_idx + 2] = 255;
        dst_row[dst_idx + 3] = 255;
      }
    }
  }

  // သုံးပြီးသား bitmap pointer ကို သေချာဖျက်ပေးခြင်း
  FPDFBitmap_Destroy(bitmap);

  return rgba_buffer;
}