// ignore_for_file: unused_import, unused_local_variable, public_member_api_docs, sort_constructors_first
// ignore_for_file: avoid_print

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:than_pdf_engine/core/pdf_doc/pdf_document.dart';
import 'package:than_pdf_engine/core/types/result.dart';
import 'package:than_pdf_engine/than_pdf_engine.dart';
import 'package:than_pdf_engine/than_pdf_engine_bindings_generated.dart';

void main() async {
  final path =
      '/home/thancoder/Documents/pdf/၁၉၆၈ခုနှစ်တွင်အင်မော်တယ်တစ်ပါးဖြစ်လာခြင်း_Book_1_3.pdf';
  final doc = PdfDocumentFile();

  final docResult = doc.open(path);
  if (docResult.isErr) {
    print(docResult.unwrapError());
    return;
  }

  print('page: ${doc.pageCount}');

  // for (var page in doc.allPages.unwrapOr([])) {
  //   print('page: $page');
  // }

  final page = PdfPage(doc);
  final pageResult = page.loadPage(0);
  if (pageResult.isErr) {
    print(pageResult.unwrapError());
    return;
  }

  final res = page.savePngImageFile('thumb.png');
  page.saveJpgImageFile('thumb.jpg');

  if (res.isErr) {
    print('Error: ${res.unwrapError()}');
    return;
  }
  print('Saved');

  doc.close();
}
