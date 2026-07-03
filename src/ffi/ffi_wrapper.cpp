#include "ffi_wrapper.h"

extern "C" {
#include "fpdfview.h"
}

// FPDF_InitLibrary
void pdfium_init() { FPDF_InitLibrary(); }

// FPDF_DestroyLibrary()
void pdfium_destroy() { FPDF_DestroyLibrary(); }