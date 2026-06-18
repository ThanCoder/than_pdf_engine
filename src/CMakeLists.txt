cmake_minimum_required(VERSION 3.10)
project(pdf_engine)


# add_library(pdf_engine_wrapper SHARED
#     ffi/than_pdf_engine.cpp
#     pdf/pdf_core.hpp
#     pdf/pdf_core.cpp
#     pdf/pdf_page.hpp
#     pdf/pdf_page.cpp
#     ffi/pdf_page_wrapper.cpp
# )


add_executable(pdf_engine_wrapper
    main.cpp
    ffi/than_pdf_engine.cpp
    pdf/pdf_core.hpp
    pdf/pdf_core.cpp
    pdf/pdf_page.hpp
    pdf/pdf_page.cpp
    ffi/pdf_page_wrapper.cpp
    stbi_impl.cpp
)


target_include_directories(pdf_engine_wrapper PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/pdf
)

target_link_libraries(pdf_engine_wrapper PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/lib/libpdfium.so
    glfw # 💡 ဒါလေး ထည့်ပေးပါ
    GL # 💡 ဒါလေး ထည့်ပေးပါ
)
