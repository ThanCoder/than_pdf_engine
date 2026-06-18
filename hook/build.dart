// ignore_for_file: avoid_print

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:logging/logging.dart';
import 'package:hooks/hooks.dart';
import 'package:path/path.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final packageName = input.packageName;
    final sourceDir = join(input.packageRoot.toFilePath(),'src');
    final pdfLibSo = join(sourceDir, 'lib', 'libpdfium.so');

    final cbuilder = CBuilder.library(
      name: packageName,
      language: .cpp,
      assetName: '${packageName}_bindings_generated.dart',
      sources: ['src/ffi/$packageName.cpp'],
      includes: [join(sourceDir, 'include')],
    );
    await cbuilder.run(
      input: input,
      output: output,
      logger: Logger('')
        ..level = .ALL
        ..onRecord.listen((record) => print(record.message)),
    );
    // copy to lib
    output.assets.code.add(
      CodeAsset(
        package: packageName,
        name: 'libpdfium.so',
        linkMode: DynamicLoadingBundled(),
        file: File(pdfLibSo).uri,
      ),
    );
  });
}
