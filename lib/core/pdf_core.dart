import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'package:than_pdf_engine/core/types.dart';
import 'package:than_pdf_engine/than_pdf_engine_bindings_generated.dart';

class PdfCore {
  Pointer<Void> _pdfCore = nullptr;
  int _pageCount = 0;
  int get pageCount => _pageCount;

  static void initPdfLib() {
    pdfium_init();
  }

  /// init
  Future<void> open(String pdfPath) async {
    try {
      _pdfCore = pdf_core_create();
      final pathPtr = pdfPath.toNativeUtf8();
      pdf_core_openFile(_pdfCore, pathPtr.cast<Char>(), nullptr);

      _pageCount = pdf_core_getPageCount(_pdfCore);
      calloc.free(pathPtr);
    } catch (e) {
      print(e);
    }
  }

  /// get all cal page size list
  Future<List<PageSize>> getAllPageSizedList() async {
    return Isolate.run(() {
      final list = <PageSize>[];
      final sizes = pdf_core_getAllPageSizes(_pdfCore);

      if (sizes != nullptr) {
        for (var i = 0; i < pageCount; i++) {
          final size = (sizes + i).ref;
          list.add(
            PageSize(pageIndex: i, width: size.width, height: size.height),
          );
        }
      }

      pdf_core_free_pageSizes(sizes.cast<Void>());
      return list;
    });
  }

  ///need to clear ram
  void dispose() {
    pdf_core_destroy(_pdfCore);
  }
}
