// ignore_for_file: unused_local_variable, public_member_api_docs, sort_constructors_first
// ignore_for_file: avoid_print

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'package:than_pdf_engine/than_pdf_engine_bindings_generated.dart';

void main() {
  final pdf = pdf_core_create();
  final pathPtr = "/home/thancoder/Documents/test3.pdf".toNativeUtf8();
  pdf_core_openFile(pdf, pathPtr.cast<Char>(), nullptr);
  final pageCount = pdf_core_getPageCount(pdf);
  print('count: ${pdf_core_getPageCount(pdf)}');

  final page = pdf_core_getPage(pdf, 0);
  final outpathPtr = "test.jpg".toNativeUtf8();

  final bufferSizePtr = calloc<Int>();

  final rgbaPtr = pdf_page_renderToRGBA(page, 1, bufferSizePtr);
  final rgbaBytes = rgbaPtr.asTypedList(bufferSizePtr.value);
  print(rgbaBytes.length);

  pdf_page_free_render_data(rgbaPtr);

  calloc.free(bufferSizePtr);

  // pdf_page_saveAsJpg(page, outpathPtr.cast<Char>(), .3, 90);

  // final sizes = pdf_core_getAllPageSizes(pdf).cast<Page_Size_Data>();

  // if (sizes != nullptr) {
  //   for (var i = 0; i < pageCount; i++) {
  //     final size = (sizes + i).ref;
  //     print('page: $i');
  //     print('width: ${size.width}');
  //     print('height: ${size.height}');
  //   }
  // }

  // pdf_core_free_pageSizes(sizes.cast<Void>());

  pdf_core_destroy(pdf);
  calloc.free(pathPtr);

  print('test');
}
