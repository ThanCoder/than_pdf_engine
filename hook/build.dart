// ignore_for_file: avoid_print

import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:path/path.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final packageName = input.packageName;
    final targetArchitecture = input.config.code.targetArchitecture;
    final targetOS = input.config.code.targetOS;

    final cacheFolder = join(
      input.packageRoot.toFilePath(),
      '.dart_tool',
      'native_assets',
    );

    // ၁။ PDFium Library ကို Download ဆွဲခြင်း
    final pdfimbLibCacheFile = await downloadPdfimbCacheLib(
      targetOS,
      targetArchitecture,
      cacheFolder,
      'libpdfium.so',
    );

    // ၂။ CMake ကနေ ထွက်ထားတဲ့ wrapper.so လမ်းကြောင်းကို ယူခြင်း
    // (သင့် CMake build output location အလိုက် လမ်းကြောင်းကို ညွှန်ပေးပါ)
    final wrapperFolder = join(
      input.packageRoot.toFilePath(),
      'src',
      'dist_binaries',
    );
    late String wrapperLibPath;
    if (targetOS == .linux) {
      wrapperLibPath = join(wrapperFolder, 'libpdf_engine_wrapper_x64.so');
    }
    if (targetOS == .android) {
      wrapperLibPath = join(wrapperFolder, switch (targetArchitecture) {
        .arm => 'libpdf_engine_wrapper_armeabi-v7a.so',
        .arm64 => 'libpdf_engine_wrapper_arm64-v8a.so',
        _ => throw UnsupportedError(
          'Unsupported: "$targetOS" - "$targetArchitecture"',
        ),
      });
    }

    // ၃။ Wrapper Library ကို Asset ထဲ ထည့်ခြင်း
    output.assets.code.add(
      CodeAsset(
        package: packageName,
        name: '${packageName}_bindings_generated.dart',
        linkMode: DynamicLoadingBundled(),
        file: File(wrapperLibPath).uri,
      ),
    );

    // ၄။ PDFium Library ကို Asset ထဲ ထည့်ခြင်း
    output.assets.code.add(
      CodeAsset(
        package: packageName,
        name: 'libpdfium.so',
        linkMode: DynamicLoadingBundled(),
        file: pdfimbLibCacheFile.uri,
      ),
    );

    print('Native assets bundled successfully!');
  });
}

//chromium%2F7891
Future<File> downloadPdfimbCacheLib(
  OS targetOS,
  Architecture targetArchitecture,
  String cacheFolder,
  String libName,
) async {
  late String downloadUrl;
  final cacheLibFile = File(
    join(cacheFolder, targetOS.name, targetArchitecture.name, libName),
  );
  final libUrl =
      'https://github.com/bblanchon/pdfium-binaries/releases/download/chromium%2F7891';
  if (targetOS == .linux) {
    // set cache path
    downloadUrl = switch (targetArchitecture) {
      .arm => '$libUrl/pdfium-linux-arm.tgz',
      .arm64 => '$libUrl/pdfium-linux-arm64.tgz',
      .x64 => '$libUrl/pdfium-linux-x64.tgz',
      .ia32 => '$libUrl/pdfium-linux-x86.tgz',
      _ => throw UnsupportedError(
        'Unsupported Linux architecture: $targetArchitecture',
      ),
    };
  } else if (targetOS == .android) {
    downloadUrl = switch (targetArchitecture) {
      .arm => '$libUrl/pdfium-android-arm.tgz',
      .arm64 => '$libUrl/pdfium-android-arm64.tgz',
      .x64 => '$libUrl/pdfium-android-x64.tgz',
      .ia32 => '$libUrl/pdfium-android-x86.tgz',
      _ => throw UnsupportedError(
        'Unsupported Linux architecture: $targetArchitecture',
      ),
    };
  }

  final cacheDir = Directory(cacheFolder);
  if (!cacheDir.existsSync()) {
    await cacheDir.create(recursive: true);
  }
  final cachePlatformDir = Directory(join(cacheFolder, targetOS.name));
  if (!cachePlatformDir.existsSync()) {
    await cachePlatformDir.create(recursive: true);
  }
  final cacheArchDir = Directory(
    join(cachePlatformDir.path, targetArchitecture.name),
  );
  if (!cacheArchDir.existsSync()) {
    await cacheArchDir.create(recursive: true);
  }

  // download for pdfium lib
  final fileName = downloadUrl.split('/').last;
  final downloadFile = File(join(cacheFolder, fileName));
  // download file မရှိရင် download လုပ်မယ်
  //cahce file မရှိဘူး နဲ့ download ထားတဲ့ file လည်းမရှိရင် download လုပ်မယ်
  if (!cacheLibFile.existsSync() && !await downloadFile.exists()) {
    print('Downloading PDFium binaries from: $downloadUrl');
    final request = await HttpClient().getUrl(Uri.parse(downloadUrl));
    final response = await request.close();
    await response.pipe(downloadFile.openWrite());
    print('Download completed.');
  }
  // lib file မရှိရင် extract လုပ်မယ်
  if (!cacheLibFile.existsSync()) {
    // Extract ဖြည်ခြင်း (.zip ဆိုရင် ZipDecoder, .tgz / .tar.gz ဆိုရင် TarDecoder သုံးပါ)
    print('Extracting archive...');
    if (fileName.endsWith('zip')) {
      final bytes = await downloadFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        if (file.isFile && file.name.endsWith('.so')) {
          if (file.name.endsWith('libpdfium.so')) {
            print('Found target library: ${file.name}');

            // file data တွေကို output file ထဲ ရေးထည့်မယ်
            final outputStream = OutputFileStream(cacheLibFile.path);
            file.writeContent(outputStream);
            await outputStream.close(); // stream ကို သေချာ ပိတ်ပေးရပါမယ်

            print('Successfully extracted to: ${cacheLibFile.path}');
            break; // ဖိုင်ရပြီဆိုရင် loop ကို ရပ်လိုက်လို့ရပါပြီ
          }
        }
      }
    } else {
      // 1. GZip နဲ့ Tar နှစ်ဆင့်လုံးကို ဖြည်ချခြင်း
      final bytes = await downloadFile.readAsBytes();
      final gzipBytes = GZipDecoder().decodeBytes(bytes);
      final archive = TarDecoder().decodeBytes(gzipBytes);

      for (final file in archive) {
        if (file.isFile && file.name.endsWith('.so')) {
          if (file.name.endsWith('libpdfium.so')) {
            print('Found target library: ${file.name}');

            // file data တွေကို output file ထဲ ရေးထည့်မယ်
            final outputStream = OutputFileStream(cacheLibFile.path);
            file.writeContent(outputStream);
            await outputStream.close(); // stream ကို သေချာ ပိတ်ပေးရပါမယ်

            print('Successfully extracted to: ${cacheLibFile.path}');
            break; // ဖိုင်ရပြီဆိုရင် loop ကို ရပ်လိုက်လို့ရပါပြီ
          }
        }
      }
    }
  }

  return cacheLibFile;
}
