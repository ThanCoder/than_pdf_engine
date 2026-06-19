cmake_minimum_required(VERSION 3.10)
project(pdf_engine)

# 1. Android NDK အတွက် C++ Runtime ကို Static Link လုပ်ခိုင်းခြင်း (libc++_shared.so မလိုတော့အောင်)
if(ANDROID)
    set(CMAKE_ANDROID_STL_TYPE "c++_static")
endif()

add_library(pdf_engine_wrapper SHARED
    ffi/than_pdf_engine.cpp
    pdf/pdf_core.hpp
    pdf/pdf_core.cpp
    pdf/pdf_page.hpp
    pdf/pdf_page.cpp
    ffi/pdf_page_wrapper.cpp
    stbi_impl.cpp
)


# add_executable(pdf_engine_wrapper
#     main.cpp
#     ffi/than_pdf_engine.cpp
#     pdf/pdf_core.hpp
#     pdf/pdf_core.cpp
#     pdf/pdf_page.hpp
#     pdf/pdf_page.cpp
#     ffi/pdf_page_wrapper.cpp
#     stbi_impl.cpp
# )


target_include_directories(pdf_engine_wrapper PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/pdf
)

# ၄။ OS အလိုက် သက်ဆိုင်ရာ Library များနှင့် Graphic APIs များ ခွဲခြား Link လုပ်ခြင်း
if(ANDROID)
    # Android အတွက် (ဥပမာ - build/toolchain ကပေးမယ့် ANDROID_ABI အလိုက် arm64-v8a စသဖြင့် ခွဲချင်ရင်)
    # လောလောဆယ် သင့် folder structure က lib/android/arm64-v8a/ အောက်မှာ ရှိတယ်ဆိုပါစို့
    target_link_libraries(pdf_engine_wrapper PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/lib/android/${ANDROID_ABI}/libpdfium.so
        log # Android native logcat သုံးနိုင်ရန် (လိုအပ်လျှင်)
        android # Android native app APIs
        # EGL # Android Graphic interface
        # GLESv3 # OpenGL ES 3.0 (Desktop က GL နေရာမှာ အစားထိုးရန်)
    )
else()
    # Linux Desktop အတွက်
    target_link_libraries(pdf_engine_wrapper PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/lib/linux/x64/libpdfium.so
        glfw
        GL
    )

    # Linux အတွက် rpath သတ်မှတ်ခြင်း
    set_target_properties(pdf_engine_wrapper PROPERTIES
        BUILD_WITH_INSTALL_RPATH TRUE
        INSTALL_RPATH "$ORIGIN"
    )
endif()


# cmake .. \
#   -DCMAKE_TOOLCHAIN_FILE=$NDK_PATH/build/cmake/android.toolchain.cmake \
#   -DANDROID_ABI=arm64-v8a \
#   -DANDROID_PLATFORM=android-21 \
#   -DCMAKE_BUILD_TYPE=Release

# အမှန်တကယ် compile လုပ်ပြီး .so ဖိုင် ထုတ်ယူခြင်း
# cmake --build .