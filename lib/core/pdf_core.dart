import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'package:than_pdf_engine/core/pdf_thumbnail_generator.dart';
import 'package:than_pdf_engine/core/types.dart';
import 'package:than_pdf_engine/than_pdf_engine_bindings_generated.dart';

class PdfCore {
  /// ### Get Pdf Page Size Class
  ///
  ///```dart
  /// class PageSize {
  ///   final int pageIndex;
  ///   final double width;
  ///   final double height;
  ///   PageSize({
  ///     required this.pageIndex,
  ///     required this.width,
  ///     required this.height,
  ///   });
  /// }
  /// ```
  ///
  static Future<(List<PageSize>, String?)> getAllPageSizedList(
    String path, {
    String? password,
  }) async {
    return await Isolate.run<(List<PageSize>, String?)>(() {
      pdfium_init();
      final list = <PageSize>[];
      final pathPtr = path.toNativeUtf8();
      final passPtr = password == null ? nullptr : password.toNativeUtf8();
      pdf_core_t corePtr = nullptr;
      page_size_data_t sizesPtr = nullptr;
      String? error;
      Pointer<Int> outCountPtr = calloc<Int>();

      try {
        corePtr = pdf_core_create();

        final isOpened = pdf_core_openFile(
          corePtr,
          pathPtr.cast<Char>(),
          password == null ? nullptr : passPtr.cast<Char>(),
        );
        // print('isOpened: $isOpened');
        if (!isOpened) {
          error = 'Failed to open PDF file: $path';
        }
        sizesPtr = pdf_core_getAllPageSizes(corePtr, outCountPtr);
        final count = outCountPtr.value;

        if (sizesPtr != nullptr) {
          final arrPtr = sizesPtr.cast<Page_Size_Data>();
          for (var i = 0; i < count; i++) {
            final size = (arrPtr + i).ref;
            list.add(
              PageSize(pageIndex: i, width: size.width, height: size.height),
            );
          }
        }
      } finally {
        calloc.free(pathPtr);
        calloc.free(outCountPtr);
        if (passPtr != nullptr) {
          calloc.free(passPtr);
        }
        if (sizesPtr != nullptr) {
          pdf_core_free_getAllPageSizes(sizesPtr);
        }
        if (corePtr != nullptr) {
          pdf_core_destroy(corePtr);
        }
      }
      return (list, error);
    });
  }

  /// ### Gen Pdf Thumbnail JPG Type
  ///
  /// Used -> `PdfThumbnailGenerator`
  static Future<bool> genThumbnailJpg(
    String pdfPath,
    String outPath, {
    int pageIndex = 0,
    String? password,
    int width = 200,
    int height = 200,
    int quality = 70,
    bool overrideImage = false,
  }) async {
    return await PdfThumbnailGenerator.instance.generate(
      pdfPath,
      outPath,
      height: height,
      width: width,
      overrideImage: overrideImage,
      pageIndex: pageIndex,
      password: password,
      quality: quality,
      type: .jpg,
    );
  }

  /// ### Gen Pdf Thumbnail PNG Type
  ///
  /// Used -> `PdfThumbnailGenerator`
  static Future<bool> genThumbnailPng(
    String pdfPath,
    String outPath, {
    int pageIndex = 0,
    String? password,
    int width = 200,
    int height = 200,
    bool overrideImage = false,
  }) async {
    return await PdfThumbnailGenerator.instance.generate(
      pdfPath,
      outPath,
      height: height,
      width: width,
      overrideImage: overrideImage,
      pageIndex: pageIndex,
      password: password,
      quality: 70,
      type: .png,
    );
  }
}
