# than_pdf_engine


`than_pdf_engine` is a high-performance C++ native wrapper class designed for rendering and processing PDF documents. This engine acts as a low-level bridge, wrapping the capabilities of Foxit's Pdfium engine through `pdfium_dart` to provide optimal execution speed and efficient memory management.

---

## 🚀 Overview

When building applications that handle high-volume or heavy PDF files, processing speed and memory safety are critical. `than_pdf_engine` is written in C++ to bypass high-level overhead, directly leveraging native binaries while providing a clean, abstract interface for your application layer.

```yaml
[ Your Application / Dart Layer ]
│
▼ (Dart FFI)
┌──────────────────────────────────────┐
│          than_pdf_engine             │  <-- This Wrapper Project
│     (C++ Native Wrapper Class)       │
└─────────────────┬────────────────────┘
│
▼
[ pdfium_dart Core Lib ]

```

## Pdfium lib native wrapper class.witten by c++.
---

## 📦 Dependencies

To integrate and build this native engine, you need to add the core Pdfium binding library into your project's dependencies.

Add the following block to your `pubspec.yaml` file:

```yaml
dependencies:
  pdfium_dart: ^latest

```
### Basic PDF Operations
- You can use the high-level PdfCore API to quickly extract page sizes or generate image thumbnails from a PDF file.
```dart

// Get list of sizes for all pages
final pageSizes = await PdfCore.getAllPageSizedList('/home/thancoder/Documents/test3.pdf');

// Generate a JPG thumbnail
await PdfCore.genThumbnailJpg(
    "/home/thancoder/Documents/test3.pdf",
    'test3.jpg',
);

// Generate a PNG thumbnail
await PdfCore.genThumbnailPng(
    "/home/thancoder/Documents/test3.pdf",
    'test3.png',
);

```
###  Using Background PDF Worker (Isolate-based)

- For heavy rendering pipelines, use PdfBackgroundWorker to offload tasks to a separate Dart Isolate. This keeps your main UI thread smooth and responsive.

```dart
// Get the singleton instance of Background Worker
final pdfWorker = PdfBackgroundWorker.getInstance;

// Initialize the worker with the target PDF file
await pdfWorker.run('/home/thancoder/Documents/test3.pdf');

// Request a specific page as a JPG image asynchronously
final pageImage = await pdfWorker.requestPageImageJpg(
    pageIndex, 
    width: width, 
    height: height,
);

// Clean up and release worker resources when done
await pdfWorker.dispose();
```

### Native Low-Level API (C++ Bindings via FFI)

- If you need direct, low-level access to the underlying C++ wrapper functions, you can invoke them directly using Dart FFI pointers.

```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:than_pdf_engine/than_pdf_engine.dart';
import 'package:than_pdf_engine/than_pdf_engine_bindings_generated.dart';

// Create the native PDF core instance
final pdf = pdf_core_create();
final pathPtr = "/home/thancoder/Documents/test3.pdf".toNativeUtf8();

// Open the PDF file at the native level
pdf_core_openFile(pdf, pathPtr.cast<Char>(), nullptr);

// Retrieve total page count
final pageCount = pdf_core_getPageCount(pdf);
print('Total Pages: $pageCount');

// Strictly manage memory: Destroy engine instance and free pointers
pdf_core_destroy(pdf);
calloc.free(pathPtr);
```