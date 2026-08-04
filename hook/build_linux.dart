// ignore_for_file: avoid_print

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:path/path.dart';

Future<void> buildLinux(
  String libName,
  BuildInput input,
  BuildOutputBuilder output,
) async {
  final packageName = input.packageName;

  final wrapperZipFile = File(
    join(
      input.packageRoot.toFilePath(),
      'native_libs',
      'pdfium-wrapper-linux-x86_64',
      libName,
    ),
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
