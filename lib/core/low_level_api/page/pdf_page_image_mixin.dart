// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../pdf_document.dart';

enum PageRenderImageType {
  jpg,
  png,
  webp;

  static PageRenderImageType fromValue(String val) {
    return values.firstWhere((e) => e.name == val, orElse: () => jpg);
  }
}

mixin PdfPageImageMixin on IPdfPage {
  /// Save File
  ///
  /// enum PageRenderImageType { jpg, png, webp }
  ///
  /// default -> `original size`
  ///
  /// `targetWidth`=0 `targetHeight`=0
  ///```dart
  ///final res = page.saveImageFile('thumb.png');
  ///
  /// if (res.isErr) {
  ///   print('Error: ${res.unwrapError()}');
  ///   return;
  /// }
  /// print('Saved');
  /// ```

  Result<bool, String> saveImageFile(
    String path, {
    int targetWidth = 0,
    int targetHeight = 0,
    int quality = 100,
    PageRenderImageType renderImageType = .jpg,
  }) {
    final res = renderPageImage(
      renderImageType: renderImageType,
      quality: quality,
      targetHeight: targetHeight,
      targetWidth: targetWidth,
    );
    if (res.isErr) {
      return Err(res.unwrapError());
    }
    File(path).writeAsBytesSync(res.unwrap());

    return Ok(true);
  }

  /// Render Page Image
  ///
  /// default -> `original size`
  ///
  /// `targetWidth`=0 `targetHeight`=0
  Result<Uint8List, String> renderPageImage({
    int targetWidth = 0,
    int targetHeight = 0,
    int quality = 100,
    PageRenderImageType renderImageType = .jpg,
  }) {
    final pixels = renderPage(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    if (pixels.isErr) {
      return Err(pixels.unwrapError());
    }
    final res = pixels.unwrap();
    late Uint8List bytes;

    try {
      if (renderImageType == .jpg) {
        bytes = img.encodeJpg(
          quality: quality,
          .fromBytes(
            width: res.width,
            height: res.height,
            bytes: res.pixels.buffer,
            order: .bgra,
          ),
        );
      } else if (renderImageType == .png) {
        bytes = img.encodePng(
          .fromBytes(
            width: res.width,
            height: res.height,
            bytes: res.pixels.buffer,
            order: .bgra,
          ),
        );
      } else if (renderImageType == .webp) {
        bytes = img.encodeWebP(
          .fromBytes(
            width: res.width,
            height: res.height,
            bytes: res.pixels.buffer,
            order: .bgra,
          ),
        );
      }
      return Ok(bytes);
    } catch (e) {
      return Err(e.toString());
    }
  }

  ///
  /// Return ->
  /// pixels data
  ///
  /// ChannelOrder -> BGRA
  ///
  /// default -> `original size`
  ///
  /// `targetWidth`=0 `targetHeight`=0
  ///
  /// ```dart
  ///  final pngBytes = img.encodePng(
  ///   .fromBytes(
  ///     width: res.width,
  ///     height: res.height,
  ///     bytes: res.pixels.buffer,
  ///     order: .bgra,
  ///   ),
  /// );
  /// ```
  Result<PdfPixels, String> renderPage({
    int targetWidth = 0,
    int targetHeight = 0,
  }) {
    final bitmap = createLowLevelBitmap(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    if (bitmap.isErr) {
      return Err(bitmap.unwrapError());
    }

    try {
      bindings.FPDFBitmap_FillRect(
        bitmap.unwrap().bitmapPtr,
        0,
        0,
        bitmap.unwrap().width,
        bitmap.unwrap().height,
        0xFFFFFFFF,
      );
      bindings.FPDF_RenderPageBitmap(
        bitmap.unwrap().bitmapPtr,
        _page,
        0,
        0,
        bitmap.unwrap().width,
        bitmap.unwrap().height,
        0,
        0,
      );

      final buffer = bindings.FPDFBitmap_GetBuffer(bitmap.unwrap().bitmapPtr);
      final stride = bindings.FPDFBitmap_GetStride(bitmap.unwrap().bitmapPtr);

      if (buffer == nullptr || stride <= 0) {
        throw StateError('Failed to get bitmap data');
      }
      final bytes = Uint8List.fromList(
        buffer.cast<Uint8>().asTypedList(stride * bitmap.unwrap().height),
      );

      // print('width: ${bitmap.unwrap().width}');
      // print('height: ${bitmap.unwrap().height}');
      // print('stride: $stride');
      // print('expected stride: ${bitmap.unwrap().width * 4}');
      return Ok(
        .new(
          width: bitmap.unwrap().width,
          height: bitmap.unwrap().height,
          pixels: bytes,
        ),
      );
    } catch (e) {
      return Err(e.toString());
    } finally {
      // free
      freeLowLevelBitmap(bitmap.unwrap());
    }
  }

  /// free low level api
  void freeLowLevelBitmap(PdfBitmap bitmap) {
    bindings.FPDFBitmap_Destroy(bitmap.bitmapPtr);
  }

  /// Low Level Bitmap
  ///
  /// default -> `original size`
  ///
  /// `targetWidth`=0 `targetHeight`=0
  ///
  /// ```dart
  ///final bitmap = createLowLevelBitmap(
  ///   targetWidth: targetWidth,
  ///   targetHeight: targetHeight,
  /// );
  /// if (bitmap.isErr) {
  ///   return Err(bitmap.unwrapError());
  /// }
  ///
  /// //free memory
  /// freeLowLevelBitmap(bitmap.unwrap());
  /// ```
  Result<PdfBitmap, String> createLowLevelBitmap({
    int targetWidth = 0,
    int targetHeight = 0,
  }) {
    final pageWidth = bindings.FPDF_GetPageWidth(_page);
    final pageHeight = bindings.FPDF_GetPageHeight(_page);
    int width;
    int height;

    if (targetWidth > 0 && targetHeight > 0) {
      width = targetWidth;
      height = targetHeight;
    } else if (targetWidth > 0) {
      width = targetWidth;
      height = (pageHeight * targetWidth / pageWidth).round();
    } else if (targetHeight > 0) {
      height = targetHeight;
      width = (pageWidth * targetHeight / pageHeight).round();
    } else {
      width = pageWidth.ceil();
      height = pageHeight.ceil();
    }
    // print('[createLowLevelBitmap] width: $width - height: $height');
    final bitmap = bindings.FPDFBitmap_Create(width, height, 1);
    if (bitmap == nullptr) {
      return Err('Failed to create bitmap');
    }

    return Ok(.new(width: width, height: height, bitmapPtr: bitmap));
  }
}
