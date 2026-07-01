// ignore_for_file: unused_local_variable, public_member_api_docs, sort_constructors_first
// ignore_for_file: avoid_print

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:than_pdf_engine/than_pdf_engine.dart';
import 'package:than_pdf_engine/than_pdf_engine_bindings_generated.dart';

void main() async {
  final pdf = pdf_core_create();
  final pathPtr = "/home/thancoder/Documents/test3.pdf".toNativeUtf8();
  pdf_core_openFile(pdf, pathPtr.cast<Char>(), nullptr);
  final pageCount = pdf_core_getPageCount(pdf);
  print('count: ${pdf_core_getPageCount(pdf)}');

  await PdfCore.genThumbnailJpg(
    "/home/thancoder/Documents/test3.pdf",
    'test3.jpg',
  );
  await PdfCore.genThumbnailPng(
    "/home/thancoder/Documents/test3.pdf",
    'test3.png',
  );

  /// get PageSize class
  ///
  // await PdfCore.getAllPageSizedList('/home/thancoder/Documents/test3.pdf');

  pdf_core_destroy(pdf);
  calloc.free(pathPtr);
  // Pdf Background Wroker
  // do isolate
  final pdfWorker = PdfBackgroundWorker.getInstance;
  
  // /// wroker init
  // await pdfWorker.run('/home/thancoder/Documents/test3.pdf');
  
  // /// current supported JPG Image
  // pdfWorker.requestPageImageJpg(pageIndex, width: width, height: height)

  // // need to stop
  // //it will call [stop] method
  // await pdfWorker.dispose();
  // same
  // await pdfWorker.stop();
}
