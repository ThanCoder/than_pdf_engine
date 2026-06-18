#include "pdf_page.hpp"

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

std::vector<uint8_t> PdfPage::renderToJpeg(float zoomFactor, int quality) {
  std::vector<uint8_t> outputJpegData;

  if (!page) return outputJpegData;

  // RGBA data (4 channels) ကို ရယူခြင်း
  auto rgba_data = renderToRGBA(zoomFactor);
  if (rgba_data.empty()) return outputJpegData;

  // 💡 [အရေးကြီးပြင်ဆင်ချက်] RGBA (4 channels) မှ RGB (3 channels) သို့ ပြောင်းလဲခြင်း
  // ဘာလို့လဲဆိုတော့ JPEG က Alpha channel ကို support မလုပ်လို့ပါ
  std::vector<uint8_t> rgb_data;
  rgb_data.reserve(width * height * 3);  // Memory ကြိုတောင်းထားမယ်

  for (size_t i = 0; i < rgba_data.size(); i += 4) {
    rgb_data.push_back(rgba_data[i]);      // R
    rgb_data.push_back(rgba_data[i + 1]);  // G
    rgb_data.push_back(rgba_data[i + 2]);  // B
    // rgba_data[i + 3] (Alpha) ကို လစ်လျူရှုလိုက်ပါတယ်
  }

  // STB သို့ လှမ်းရေးခိုင်းခြင်း (Component နေရာမှာ JPEG ဖြစ်လို့ '3' ကိုပဲ သုံးရပါမယ်)
  stbi_write_jpg_to_func(stbi_write_to_vector, &outputJpegData, width, height,
                         3, rgb_data.data(), quality);

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