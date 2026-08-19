// ignore_for_file: unused_import

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:than_pdf_engine/than_pdf_engine_bindings_generated.dart';

export 'core/models/page_size.dart';
export 'core/types/index.dart';
export 'core/high_level_api/index.dart';

// const String testPath = '/home/thancoder/projects/dart_plugins/than_pdf_engine/.dart_tool/lib/libpdfium.so';

final dylib = DynamicLibrary.open('libpdfium.so');
final bindings = ThanPdfEngineBindings(dylib);
