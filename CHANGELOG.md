# 1.1.0
* Fixed `PdfImageGenerator`
# 1.0.0

### Previous Architecture

The project previously used a custom C++ wrapper around PDFium:

```text
Dart
  │
  ▼
Dart FFI
  │
  ▼
C++ Wrapper
  │
  ▼
PDFium
```

The C++ wrapper layer has now been removed.

### Current Architecture

The current implementation communicates with PDFium directly through Dart FFI:

```text
Dart
  │
  ▼
Dart FFI
  │
  ▼
PDFium
  │
  ▼
Rendered Bitmap
  │
  ▼
Dart Image Processing
  │
  ▼
PNG / JPEG
```

## 0.5.0

* Fixed Error `PdfThumbnailGenerator` -> `App Force Closed.`
# 0.4.0

## Dart

* Deprecated `requestPageImageJpg`
* Added `requestPageImage`

## Native C++

* Added `pdf_page_renderToPngWH`
* Added `pdf_page_free_renderToPngWH`
* Changed `pdf_core_getAllPageSizes` -> `C++ Codes`
# 0.3.0
* Added `PdfThumbnailGenerator`
-
* Fixed `PdfCore:genThumbnailJpg` - changed -> `PdfThumbnailGenerator:generate`
* Fixed `PdfCore:genThumbnailPng` - changed -> `PdfThumbnailGenerator:generate`
* Fixed `PdfBackgroundWorker` - background function error.
# 0.2.1
* Fixed `Auto Force Close App Error` -> `PdfCore:genThumbnailJpg`

## 0.1.0

* initial release.
