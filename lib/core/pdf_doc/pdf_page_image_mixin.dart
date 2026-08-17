// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'pdf_document.dart';

mixin PdfPageImageMixin on IPdfPage {
  /// Save Png File
  Result<bool, String> saveJpgImageFile(
    String path, {
    int targetWidth = 0,
    int targetHeight = 0,
    int quality = 100,
  }) {
    final pixels = renderPage(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    if (pixels.isErr) {
      return Err(pixels.unwrapError());
    }
    final res = pixels.unwrap();
    final pngBytes = img.encodeJpg(
      quality: quality,
      .fromBytes(
        width: res.width,
        height: res.height,
        bytes: res.pixels.buffer,
        order: .bgra,
      ),
    );
    File(path).writeAsBytesSync(pngBytes);

    return Ok(true);
  }

  /// Save Png File
  Result<bool, String> savePngImageFile(
    String path, {
    int targetWidth = 0,
    int targetHeight = 0,
  }) {
    final pixels = renderPage(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    if (pixels.isErr) {
      return Err(pixels.unwrapError());
    }
    final res = pixels.unwrap();
    final pngBytes = img.encodePng(
      .fromBytes(
        width: res.width,
        height: res.height,
        bytes: res.pixels.buffer,
        order: .bgra,
      ),
    );
    File(path).writeAsBytesSync(pngBytes);

    return Ok(true);
  }

  ///
  /// Return ->
  /// pixels data
  ///
  /// ChannelOrder -> BGRA
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
      FPDFBitmap_FillRect(
        bitmap.unwrap().bitmapPtr,
        0,
        0,
        bitmap.unwrap().width,
        bitmap.unwrap().height,
        0xFFFFFFFF,
      );
      FPDF_RenderPageBitmap(
        bitmap.unwrap().bitmapPtr,
        _page,
        0,
        0,
        bitmap.unwrap().width,
        bitmap.unwrap().height,
        0,
        0,
      );

      final buffer = FPDFBitmap_GetBuffer(bitmap.unwrap().bitmapPtr);
      final stride = FPDFBitmap_GetStride(bitmap.unwrap().bitmapPtr);

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
    FPDFBitmap_Destroy(bitmap.bitmapPtr);
  }

  /// Need To Free
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
  /// freeLowLevelBitmap(bitmap.unwrap());
  /// ```
  Result<PdfBitmap, String> createLowLevelBitmap({
    int targetWidth = 0,
    int targetHeight = 0,
  }) {
    final pageWidth = FPDF_GetPageWidth(_page);
    final pageHeight = FPDF_GetPageHeight(_page);
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
    final bitmap = FPDFBitmap_Create(width, height, 1);
    if (bitmap == nullptr) {
      return Err('Failed to create bitmap');
    }

    return Ok(.new(width: width, height: height, bitmapPtr: bitmap));
  }
}
