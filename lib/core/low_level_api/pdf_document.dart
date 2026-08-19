// ignore_for_file: unused_element, non_constant_identifier_names

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:than_pdf_engine/core/types/result.dart';
import 'package:than_pdf_engine/than_pdf_engine.dart';
import 'package:than_pdf_engine/than_pdf_engine_bindings_generated.dart';
import 'package:image/image.dart' as img;

part 'page/pdf_page.dart';
part 'logic/pdf_doc_extra_mixin.dart';
part 'page/pdf_page_image_mixin.dart';
part 'doc/pdf_document_file.dart';
part 'doc/pdf_document_mem.dart';
part 'doc/pdf_document_mem_64.dart';

// part 'pdf_document_custom.dart';

sealed class IPdfDocument {
  Pointer<fpdf_document_t__> get _doc;

  bool get isOpened;
}
