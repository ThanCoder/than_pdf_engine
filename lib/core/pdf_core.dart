import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'package:than_pdf_engine/core/types.dart';
import 'package:than_pdf_engine/than_pdf_engine_bindings_generated.dart';

class PdfCore {
  /// get all cal page size list
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
}
