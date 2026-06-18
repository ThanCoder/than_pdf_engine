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

std::uint8_t* PdfPage::getBitmapSourcePtr(float zoomFactor) {
  if (current_bitmap) {
    FPDFBitmap_Destroy(current_bitmap);
    current_bitmap = nullptr;
  }

  int targetWidth = getRenderWith(zoomFactor);
  int targetHeight = getRenderHeight(zoomFactor);

  current_bitmap = FPDFBitmap_Create(targetWidth, targetHeight, 1);
  if (!current_bitmap) return nullptr;

  FPDFBitmap_FillRect(current_bitmap, 0, 0, targetWidth, targetHeight,
                      0xFFFFFFFF);

  // 💡 စာလုံးတင်မကဘဲ PDF ထဲက ပုံတွေပါ အကြည်ဆုံး Quality နဲ့ ဆွဲပေးဖို့ Flag အသစ်တွေ ပေါင်းထည့်လိုက်ပါတယ်
  int renderFlags = FPDF_LCD_TEXT | FPDF_RENDER_FORCEHALFTONE | FPDF_ANNOT;

  // Render လုပ်တဲ့အခါ ဒီ Flags တွေကို ထည့်ပေးရပါမယ်
  FPDF_RenderPageBitmap(current_bitmap, page, 0, 0, targetWidth, targetHeight,
                        0, renderFlags);

  // Buffer Pointer ကို ပြန်ပေးမယ် (Destruction မလုပ်တော့လို့ Pointer က သုံးလို့ရနေပါပြီ)
  return static_cast<uint8_t*>(FPDFBitmap_GetBuffer(current_bitmap));
}

std::vector<uint8_t> PdfPage::renderToRGBA(float zoomFactor) {
  std::vector<uint8_t> rgba_buffer;

  if (!page) return rgba_buffer;

  int targetWidth = getRenderWith(zoomFactor);
  int targetHeight = getRenderHeight(zoomFactor);

  std::uint8_t* source_buffer = getBitmapSourcePtr(zoomFactor);
  if (!source_buffer) return rgba_buffer;

  // 💡 [အရေးကြီး] current_bitmap ဆောက်စဉ်က FPDFBitmap_BGRA (1) နဲ့ ဆောက်ထားမှ
  // ဒီ Stride နဲ့ (x * 4) တွက်ချက်မှုက ကွက်တိမှန်မှာ ဖြစ်ပါတယ်
  int stride = FPDFBitmap_GetStride(current_bitmap);

  rgba_buffer.resize(targetWidth * targetHeight * 4);

  for (int y = 0; y < targetHeight; ++y) {
    // Row တစ်ခုချင်းစီရဲ့ အစ Pointer ကို ယူလိုက်တာက ပိုမြန်ပြီး စိတ်ချရပါတယ်
    uint8_t* src_row = source_buffer + (y * stride);
    uint8_t* dst_row = rgba_buffer.data() + (y * targetWidth * 4);

    for (int x = 0; x < targetWidth; ++x) {
      int src_x = x * 4;
      int dst_x = x * 4;

      // BGRA -> RGBA ပြောင်းလဲခြင်း
      dst_row[dst_x + 0] = src_row[src_x + 2];  // R
      dst_row[dst_x + 1] = src_row[src_x + 1];  // G
      dst_row[dst_x + 2] = src_row[src_x + 0];  // B
      dst_row[dst_x + 3] = src_row[src_x + 3];  // A
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
  // RGBA data ကို ယူမယ်
  auto rgba_data = renderToRGBA(zoomFactor);
  if (rgba_data.empty()) return false;

  // stbi_write_png ကို သုံးပြီး ဖိုင်အဖြစ် တိုက်ရိုက်သိမ်းမယ်
  // (RGBA ဖြစ်လို့ component နေရာမှာ 4 သုံးပါတယ်)
  int success = stbi_write_png(outPath.c_str(), width, height, 4,
                               rgba_data.data(), width * 4);

  return success != 0;
}

bool PdfPage::saveAsJpg(const std::string& outPath, float zoomFactor,
                        int quality) {
  // RGBA data ကို ယူမယ်
  auto rgba_data = renderToRGBA(zoomFactor);
  if (rgba_data.empty()) return false;

  // stbi_write_png ကို သုံးပြီး ဖိုင်အဖြစ် တိုက်ရိုက်သိမ်းမယ်
  // (RGBA ဖြစ်လို့ component နေရာမှာ 4 သုံးပါတယ်)
  int success = stbi_write_jpg(outPath.c_str(), width, height, 4,
                               rgba_data.data(), width * 4);

  return success != 0;
}