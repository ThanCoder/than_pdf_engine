#include <GLFW/glfw3.h>

#include <cstdint>
#include <fstream>
#include <iostream>
#include <vector>

#include "ffi/ffi_wrapper.h"

extern "C" {
#include <fpdfview.h>
#include <stb_image_write.h>
}
/**
Pdfium

MAJOR=150
MINOR=0
BUILD=7869
PATCH=0
 */

void saveBuffer(const std::vector<uint8_t>& buff, const std::string& outpath) {
  if (buff.empty()) {
    std::cerr << "buff is empty\n";
    return;
  }
  std::ofstream outFile(outpath, std::ios::out | std::ios::binary);
  if (!outFile.is_open()) {
    std::cerr << "File open error\n";
    return;
  }
  outFile.write(reinterpret_cast<const char*>(buff.data()), buff.size());

  if (!outFile) {
    std::cerr << "Write Error\n";
    return;
  }
  outFile.close();
  std::cout << "Writed: " << outpath << "\n";
}

// Window Size
const int SCREEN_WIDTH = 800;
const int SCREEN_HEIGHT = 600;

// 💡 width နဲ့ height ကိုပါ ပါရာမီတာအဖြစ် ထည့်တောင်းလိုက်ပါတယ်
int showRGBAImage(const std::vector<uint8_t>& buff, int imgWidth,
                  int imgHeight) {
  // ၁။ GLFW ကို Initialize လုပ်ခြင်း
  if (!glfwInit()) {
    std::cerr << "GLFW Init ကျရှုံးခဲ့ပါတယ်!" << std::endl;
    return -1;
  }

  // 💡 Window ကိုလည်း ပုံရဲ့ size အတိုင်း သို့မဟုတ် သင့်တော်သလို ဖွင့်လို့ရအောင် ပြင်ပါ
  GLFWwindow* window = glfwCreateWindow(imgWidth, imgHeight,
                                        "RGBA PDF Render Tester", NULL, NULL);
  if (!window) {
    glfwTerminate();
    return -1;
  }
  glfwMakeContextCurrent(window);

  // OpenGL Texture သတ်မှတ်ခြင်း
  GLuint texture;
  glGenTextures(1, &texture);
  glBindTexture(GL_TEXTURE_2D, texture);

  // Linear Filter ပြောင်းပေးရင် စာလုံးတွေ ပိုကြည်လာပါလိမ့်မယ်
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

  // 🔍 [အဓိကပြင်ဆင်ချက်] ပုံသေသတ်မှတ်ထားတဲ့ 256 နေရာမှာ တကယ့် width, height တွေ အစားထိုးလိုက်ပါပြီ
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imgWidth, imgHeight, 0, GL_RGBA,
               GL_UNSIGNED_BYTE, buff.data());

  // Main Loop
  while (!glfwWindowShouldClose(window)) {
    glClear(GL_COLOR_BUFFER_BIT);

    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, texture);

    // 💡 OpenGL မှာ PDF ပုံ ဇောက်ထိုးမဖြစ်အောင် UV Coordinates ကို Flip လှန်ပေးလိုက်ပါတယ်
    glBegin(GL_QUADS);
    glTexCoord2f(0.0f, 1.0f);
    glVertex2f(-1.0f, -1.0f);  // (0.0f, 0.0f) မှ (0.0f, 1.0f) သို့
    glTexCoord2f(1.0f, 1.0f);
    glVertex2f(1.0f, -1.0f);  // (1.0f, 0.0f) မှ (1.0f, 1.0f) သို့
    glTexCoord2f(1.0f, 0.0f);
    glVertex2f(1.0f, 1.0f);  // (1.0f, 1.0f) မှ (1.0f, 0.0f) သို့
    glTexCoord2f(0.0f, 0.0f);
    glVertex2f(-1.0f, 1.0f);  // (0.0f, 1.0f) မှ (0.0f, 0.0f) သို့
    glEnd();

    glfwSwapBuffers(window);
    glfwPollEvents();
  }

  glDeleteTextures(1, &texture);
  glfwDestroyWindow(window);
  glfwTerminate();
  return 0;
}

void saveData(std::vector<uint8_t>& buff, const std::string& path) {
  if (buff.empty()) return;
  std::ofstream outFile(path, std::ios::out | std::ios::binary);

  if (!outFile.is_open()) return;
  outFile.write(reinterpret_cast<const char*>(buff.data()), buff.size());
  outFile.close();
}

int main() {
  FPDF_InitLibrary();
  std::string currentPath =
      "/home/thancoder/projects/flutter_ffi_projects/than_pdf_engine/";

  auto path = "/home/thancoder/Documents/test_sm.pdf";

  // PdfCore core;
  // if (!core.openFile(path)) {
  //   std::cerr << "Load Fail \n";
  //   return 1;
  // }
  // std::cout << "page count: " << core.getPageCount() << "\n";

  // PdfPage page{&core, 0};

  // page.saveAsPngWH(currentPath + "test.png", 300, 300);
  // page.saveAsJpgWH(currentPath + "test.jpg", 100, 100);
  // auto data = page.renderToJpegWH(200, 200);

  // std::cout << "data size: " << data.size() << "\n";
  // // saveData(data, "../test.jpg");
  // std::ofstream outFile(currentPath + "image.jpg",
  //                       std::ios::out | std::ios::binary);
  // outFile.write(reinterpret_cast<const char*>(data.data()), data.size());
  // outFile.flush();
  // outFile.close();
  return 0;
}