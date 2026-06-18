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
    final sourceDir = join(input.packageRoot.toFilePath(), 'src');
    String libDir = join(sourceDir, 'lib');
    String pdfLibSo = join(libDir, 'libpdfium.so');

    if (input.config.code.targetOS == .android) {
      pdfLibSo = join(libDir, 'android_arm64/libpdfium.so');
      libDir = join(libDir, 'android_arm64');
      final libcxxPath = join(libDir, 'libc++_shared.so');

      output.assets.code.add(
        CodeAsset(
          package: packageName,
          name: 'libc++_shared.so',
          linkMode: DynamicLoadingBundled(),
          file: File(libcxxPath).uri,
        ),
      );
    }

    final cbuilder = CBuilder.library(
      name: packageName,
      language: .cpp,
      assetName: '${packageName}_bindings_generated.dart',
      sources: [
        'src/ffi/than_pdf_engine.cpp',
        'src/ffi/pdf_page_wrapper.cpp',
        'src/pdf/pdf_core.cpp',
        'src/pdf/pdf_page.cpp',
        'src/stbi_impl.cpp',
      ],
      includes: [
        join(sourceDir, 'include'),
        join(sourceDir, 'ffi'),
        join(sourceDir, 'pdf'),
      ],

      flags: [
        '-L$libDir', // Linker ကို ဘယ် folder ထဲမှာ library ရှာရမလဲဆိုတာ ပြတာ
        '-lpdfium', // libpdfium.so ကို link လုပ်ခိုင်းတာ (lib နဲ့ .so ဖြုတ်ပြီး ရေးရပါတယ်)
        if (input.config.code.targetOS == .android)
          '-static-libstdc++'
        else
          '-Wl,-rpath,\$ORIGIN', // Runtime မှာ ကိုယ့်ဘေးနားက library ကို ရှာခိုင်းတာ
        '-O3',
      ],
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
