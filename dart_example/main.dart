// ignore_for_file: avoid_print

import 'dart:io';

import 'package:than_pdf_engine/than_pdf_engine.dart';

void main() async {
  final dir = Directory('/home/thancoder/Documents/pdf');
  final outDir = Directory('${dir.path}/thumbs');

  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  for (var file in dir.listSync()) {
    if (file is! File) continue;
    final name = file.path.split('/').last;
    if (!name.endsWith('.pdf')) continue;
    final parts = name.split('.');
    parts.removeLast();
    final nameOnly = parts.join();

    await PdfThumbnailGenerator.instance.generate(
      file.path,
      '${outDir.path}/$nameOnly.png',
    );

    print(file);
  }
}
