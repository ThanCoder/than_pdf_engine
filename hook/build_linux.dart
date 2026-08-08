// ignore_for_file: avoid_print

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:than_pdf_engine/core/util_ext.dart';

Future<void> buildLinux(
  String libName,
  BuildInput input,
  BuildOutputBuilder output,
) async {
  final packageName = input.packageName;

  final wrapperZipFile = File(
    input.packageRoot
        .toFilePath()
        .join('native_libs')
        .join('pdfium-wrapper-linux-x86_64')
        .join(libName),
  );

  // ၃။ Wrapper Library ကို Asset ထဲ ထည့်ခြင်း
  output.assets.code.add(
    CodeAsset(
      package: packageName,
      name: '${packageName}_bindings_generated.dart',
      linkMode: DynamicLoadingBundled(),
      file: wrapperZipFile.uri,
    ),
  );

  print('Native assets bundled successfully!');
}
