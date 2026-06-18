#include <GLFW/glfw3.h>

#include <cstdint>
#include <fstream>
#include <iostream>
#include <vector>

#include "pdf/pdf_core.hpp"

extern "C" {
#define STB_IMAGE_WRITE_IMPLEMENTATION
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

int main() {
  auto path = "/home/thancoder/Documents/test_sm.pdf";
  PdfCore pdf;
  if (!pdf.openFile(path)) {
    std::cerr << "Load Fail \n";
    return 1;
  }
  std::cout << "page count: " << pdf.getPageCount() << "\n";

  auto page = pdf.getPage(1);
  auto sizes = pdf.getAllPageSizes();

  std::cout << "sizes: "<< sizes.size() << "\n";
  // float zoom = 1.5;
  // auto buff = page.renderToRGBA(zoom);
  // showRGBAImage(buff, page.getRenderWith(zoom), page.getRenderHeight(zoom));

  // if (!page.saveAsPng("../1.png", 1)) {
  //   return 1;
  // }
  // page.renderToRGBA()
  // auto buff = page.renderToJpeg(0.2);
  // saveBuffer(buff, "../save_buff.jpg");

  // if (!page.saveAsJpg("../1.jpg", 1)) {
  //   return 1;
  // }

  return 0;
}