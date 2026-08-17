// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ffi';
import 'dart:typed_data';

import 'package:than_pdf_engine/than_pdf_engine_bindings_generated.dart';

class PdfBitmap {
  final int width;
  final int height;
  final Pointer<fpdf_bitmap_t__> bitmapPtr;
  const PdfBitmap({
    required this.width,
    required this.height,
    required this.bitmapPtr,
  });
}

class PdfPixels {
  final int width;
  final int height;
  final Uint8List pixels;
  const PdfPixels({
    required this.width,
    required this.height,
    required this.pixels,
  });
}
