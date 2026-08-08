// ignore_for_file: avoid_print

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:than_pdf_engine/core/util_ext.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final targetOS = input.config.code.targetOS;
    final libName = 'libpdfium_wrapper.so';

    final outLibFolder = Directory(
      input.packageRoot.toFilePath().join('.dart_tool').join('lib'),
    );
    if (!outLibFolder.existsSync()) {
      await outLibFolder.create(recursive: true);
    }
    // final libFile = File(join(outLibFolder.path, libName));

    if (targetOS == .linux) {
      await linuxLib(libName, input, output);
    } else if (targetOS == .android) {
      await androidLib(libName, input, output);
    }
    // await buildAllPlatfroms(input, output);
  });
}

Future<void> linuxLib(
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

Future<void> androidLib(
  String libName,
  BuildInput input,
  BuildOutputBuilder output,
) async {
  final packageName = input.packageName;
  final targetArchitecture = input.config.code.targetArchitecture;

  final nativeName = switch (targetArchitecture) {
    .arm => 'pdfium-wrapper-android-arm',
    .arm64 => 'pdfium-wrapper-android-arm64',

    _ => UnsupportedError('$targetArchitecture'),
  };

  final wrapperZipFile = File(
    input.packageRoot
        .toFilePath()
        .join('native_libs')
        .join(nativeName.toString())
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
