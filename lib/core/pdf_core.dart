import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
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
  static Future<List<PageSize>> getAllPageSizedList(
    String path, {
    String? password,
  }) async {
    return Isolate.run(() {
      pdfium_init();
      final list = <PageSize>[];
      final pathPtr = path.toNativeUtf8();
      final passPtr = password == null ? nullptr : password.toNativeUtf8();

      final core = pdf_core_create();
      pdf_core_openFile(
        core,
        pathPtr.cast<Char>(),
        password == null ? nullptr : passPtr.cast<Char>(),
      );
      final pageCount = pdf_core_getPageCount(core);
      final sizes = pdf_core_getAllPageSizes(core);

      if (sizes != nullptr) {
        for (var i = 0; i < pageCount; i++) {
          final size = (sizes + i).ref;
          list.add(
            PageSize(pageIndex: i, width: size.width, height: size.height),
          );
        }
      }

      calloc.free(pathPtr);
      calloc.free(passPtr);
      pdf_core_free_pageSizes(sizes.cast<Void>());
      return list;
    });
  }

  /// ### Gen Pdf Thumbnail JPG Type
  static Future<bool> genThumbnailJpg(
    String pdfPath,
    String outpath, {
    int pageIndex = 0,
    String? password,
    int width = 200,
    int height = 200,
    int quality = 70,
  }) async {
    return Isolate.run(() {
      pdfium_init();
      final pdfPathPtr = pdfPath.toNativeUtf8();
      final outPathPtr = outpath.toNativeUtf8();
      Pointer<Utf8> passwordPtr = nullptr;
      if (password != null) {
        passwordPtr = password.toNativeUtf8();
      }
      try {
        pdf_util_saveJpgWithIndex(
          pdfPathPtr.cast<Char>(),
          password == null ? nullptr : passwordPtr.cast<Char>(),
          outPathPtr.cast<Char>(),
          pageIndex,
          width,
          height,
          quality,
        );
      } catch (e) {
        return false;
      } finally {
        calloc.free(pdfPathPtr);
        calloc.free(outPathPtr);
        if (passwordPtr != nullptr) {
          calloc.free(passwordPtr);
        }
      }
      return true;
    });
  }

  /// ### Gen Pdf Thumbnail PNG Type
  static Future<bool> genThumbnailPng(
    String pdfPath,
    String outpath, {
    int pageIndex = 0,
    String? password,
    int width = 200,
    int height = 200,
  }) async {
    return Isolate.run(() {
      pdfium_init();
      final pdfPathPtr = pdfPath.toNativeUtf8();
      final outPathPtr = outpath.toNativeUtf8();
      Pointer<Utf8> passwordPtr = nullptr;
      if (password != null) {
        passwordPtr = password.toNativeUtf8();
      }
      try {
        pdf_util_savePngWithIndex(
          pdfPathPtr.cast<Char>(),
          password == null ? nullptr : passwordPtr.cast<Char>(),
          outPathPtr.cast<Char>(),
          pageIndex,
          width,
          height,
        );
      } catch (e) {
        return false;
      } finally {
        calloc.free(pdfPathPtr);
        calloc.free(outPathPtr);
        if (passwordPtr != nullptr) {
          calloc.free(passwordPtr);
        }
      }
      return true;
    });
  }
}
