# Than PDF Engine

A lightweight PDF engine for Dart and Flutter built on top of **PDFium** using **Dart FFI** .

The engine communicates directly with PDFium through Dart FFI without using a custom C++ wrapper. PDF rendering is handled by PDFium, while image processing and encoding are handled on the Dart side using the [ `image` ](https://pub.dev/packages/image) package.

## Features

* Direct PDFium integration through Dart FFI
* No custom C++ wrapper layer
* Open and close PDF documents
* Get PDF page count
* Load individual pages
* Render PDF pages to image data
* Save rendered pages as image files
* Generate PDF thumbnails
* PNG and JPEG image output
* Dart-side image processing and encoding
* Result-based error handling
* Designed for Dart and Flutter applications

## Architecture

The current implementation uses a simple architecture:

```text
┌──────────────────────────┐
│       Dart / Flutter     │
├──────────────────────────┤
│     Than PDF Engine      │
├──────────────────────────┤
│        Dart FFI          │
├──────────────────────────┤
│          PDFium          │
└──────────────────────────┘
             │
             ▼
      Rendered Pixel Data
             │
             ▼
┌──────────────────────────┐
│       image package      │
│   PNG / JPEG encoding    │
└──────────────────────────┘
```

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

This keeps the native layer small and allows image processing to remain on the Dart side.

## Dependencies

The engine uses [ `pdfium_dart` ](https://pub.dev/packages/pdfium_dart) to access the PDFium C API through Dart FFI.

Add the dependency to your `pubspec.yaml` :

```yaml
dependencies:
  pdfium_dart: ^0.2.5
```

The project also uses the [ `image` ](https://pub.dev/packages/image) package for image processing and encoding.

## Why Dart FFI?

The project originally used a custom C++ wrapper to expose PDFium functionality to Dart.

The current implementation uses Dart FFI directly instead.

This provides several advantages:

* Less native wrapper code
* A simpler architecture
* Fewer C++ APIs to maintain
* Direct access to PDFium functions
* Easier integration with Dart-side image processing
* Better separation between PDF rendering and image encoding
* Easier maintenance of the native layer

PDFium is responsible for PDF parsing and page rendering, while Dart handles the resulting image data.

## Related Package

Looking for a complete Flutter PDF reader built on top of `than_pdf_engine` ?

Check out [ `t_pdf_reader` ](https://pub.dev/packages/t_pdf_reader).

`t_pdf_reader` uses `than_pdf_engine` as its core PDF rendering engine and provides a higher-level Flutter PDF reader experience for displaying and interacting with PDF documents.

* [`Basic Usage`](#basic-usage)
* [`Open a PDF`](#open-a-pdf)
* [`Load a Page`](#load-a-page)
* [`Render a Page`](#render-a-page)
* [`Open a Document`](#open-a-document)
* [`Close the Document`](#close-the-document)
* [`Generate PDF Thumbnails`](#generate-pdf-thumbnails)
* [`Generate Thumbnails for Multiple PDFs`](#generate-thumbnails-for-multiple-pdfs)
* [`Save a Page as an Image`](#save-a-page-as-an-image)
* [`Low-Level API`](#low-level-api)
* [`Open a PDF`](#open-a-pdf)
* [`Error Handling`](#error-handling)
* [`Features`](#features)
* [`Architecture`](#architecture)
* [`Current Architecture`](#current-architecture)
* [`Image Processing`](#image-processing)
* [`Goals`](#goals)
<!-- * [ `Basic Usage` ](#) -->

## Image Processing

PDFium renders a PDF page into a bitmap buffer.

The rendered pixel data is accessed from Dart through FFI and converted into an image using the `image` package.

```text
PDF Page
   │
   ▼
PDFium Renderer
   │
   ▼
PDFium Bitmap
   │
   ▼
Raw Pixel Buffer
   │
   ▼
Dart FFI
   │
   ▼
image package
   │
   ├── PNG
   └── JPEG
```

This keeps image encoding outside of the PDFium wrapper layer.

## Basic Usage

### Open a PDF

```dart
final reader = PdfReaderWorker();

final result = await reader.open('/path/to/document.pdf');

if (result.isErr) {
  print('Open error: ${result.unwrapError().status}');
  return;
}
```

### Render a Page

```dart
final result = await reader.getImage(0);

if (result.isErr) {
  print('Image error: ${result.unwrapError()}');
  return;
}

final imageData = result.unwrap();

print(imageData);
```

### Close the Document

```dart
await reader.close();
```

## Low-Level API

The low-level API can also be used directly when more control over the document and page lifecycle is required.

### Open a Document

```dart
final document = PdfDocumentFile();
//final doc = PdfDocumentMem(); //memory bytes
//final doc = PdfDocumentMem64();//memory 64 bytes

final result = document.open('/path/to/document.pdf');

if (result.isErr) {
  print(result.unwrapError());
  return;
}

print('Pages: ${document.pageCount}');
```

### Load a Page

```dart
final page = PdfPage(document);

final result = page.loadPage(0);

if (result.isErr) {
  print(result.unwrapError());
  page.close();
  return;
}
```

### Save a Page as an Image

```dart
final result = page.saveImageFile('page.png');

if (result.isErr) {
  print('Error: ${result.unwrapError()}');
  return;
}
```

## Generate PDF Thumbnails

The engine can also generate thumbnails from PDF documents.

```dart
final result = await PdfImageGenerator.instance.generate(
  '/path/to/document.pdf',
  outPath: '/path/to/output.jpg',
);

if (result.isOk) {
  print('Generated: ${result.unwrap()}');
}
```

### Generate Thumbnails for Multiple PDFs

```dart
final dir = Directory('/path/to/pdf');
final outDir = Directory('${dir.path}/gen');

if (!outDir.existsSync()) {
  outDir.createSync(recursive: true);
}

for (final file in dir.listSync()) {
  final name = file.path.split('/').last;

  final parts = name.split('.');
  parts.removeLast();

  final nameOnly = parts.join('.');

  final result = await PdfImageGenerator.instance.generate(
    file.path,
    outPath: '${outDir.path}/$nameOnly.jpg',
  );

  if (result.isOk) {
    print('Generated: $nameOnly');
  }
}
```

## Error Handling

The project uses a `Result<T, E>` style API instead of relying entirely on exceptions.

```dart
final result = document.open(path);

if (result.isErr) {
  final error = result.unwrapError();
  print(error);
  return;
}

final document = result.unwrap();
```

This makes errors from the PDFium layer easier to propagate through the Dart API.

## Project Structure

```text
lib/
├── core/
│   ├── high_level_api/
│   │   └── reader/
│   │       └── pdf_reader_worker.dart
│   │
│   ├── low_level_api/
│   │   └── pdf_document.dart
│   │
│   └── types/
│       └── result.dart
│
├── than_pdf_engine.dart
└── than_pdf_engine_bindings_generated.dart
```

The generated FFI bindings are created from the PDFium C headers and are used directly by the Dart implementation.

## Native Dependencies

The engine depends on **PDFium** for PDF parsing and page rendering.

Dart FFI is used to access the PDFium C API.

There is no custom C++ PDFium wrapper in the current implementation.

```text
Dart
 └── Dart FFI
      └── PDFium
```

## Goals

The main goal of Than PDF Engine is to provide a simple and efficient PDF rendering layer for Dart and Flutter applications without introducing an unnecessary native wrapper layer.

The project focuses on:

* Direct PDFium access
* Minimal native code
* Dart-friendly APIs
* Efficient page rendering
* Image generation
* Flutter integration
* Simple error handling

## Status

This project is currently under active development.

The API may change as more PDFium functionality is exposed through the Dart FFI layer.

## License

License information will be added when the project is ready for release.
