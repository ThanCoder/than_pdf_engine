// ignore_for_file: unused_import, unused_local_variable, public_member_api_docs, sort_constructors_first
// ignore_for_file: avoid_print

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:than_pdf_engine/core/low_level_api/pdf_document.dart';
import 'package:than_pdf_engine/core/types/result.dart';
import 'package:than_pdf_engine/than_pdf_engine.dart';
import 'package:than_pdf_engine/than_pdf_engine_bindings_generated.dart';

void main() async {
  final path =
      '/home/thancoder/Documents/pdf/၁၉၆၈ခုနှစ်တွင်အင်မော်တယ်တစ်ပါးဖြစ်လာခြင်း_Book_1_3.pdf';
  await openOne(path);
  // await genImage();
}

Future<void> openOne(String path) async {
  final reader = PdfReaderWorker();

  final res = await reader.open(path);

  if (res.isErr) {
    print('open Error: ${res.unwrapError().status}');
    return;
  }

  final imageRes = await reader.getImage(0);
  if (imageRes.isErr) {
    print('image Error: ${imageRes.unwrapError()}');
  } else {
    // data
    print('image: ${imageRes.unwrap()}');
  }

  print('wait 3 sec');
  await Future.delayed(Duration(seconds: 3));
  await reader.close();
}

Future<void> genImage() async {
  final dir = Directory('/home/thancoder/Documents/pdf');
  final outDir = Directory('${dir.path}/gen');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  for (var f in dir.listSync()) {
    final name = f.path.split('/').last;
    final nameParts = name.split('.');
    nameParts.removeLast();
    final nameOnly = nameParts.join('.');

    final res = await PdfImageGenerator.instance.generate(
      f.path,
      outPath: '${outDir.path}/$nameOnly.jpg',
    );
    if (res.isOk) {
      print('generated: ${res.unwrap()}-$nameOnly');
    }
  }
}

void genOne() {
  final path =
      '/home/thancoder/Documents/pdf/၁၉၆၈ခုနှစ်တွင်အင်မော်တယ်တစ်ပါးဖြစ်လာခြင်း_Book_1_3.pdf';
  final doc = PdfDocumentFile();
  // final doc = PdfDocumentMem();
  // final doc = PdfDocumentMem64();

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
    page.close();
    return;
  }

  final res = page.saveImageFile('thumb.png');

  if (res.isErr) {
    print('Error: ${res.unwrapError()}');
    return;
  }
  print('Saved');

  doc.close();
}
