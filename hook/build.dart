import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:path/path.dart';

import 'build_linux.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final targetOS = input.config.code.targetOS;
    final libName = 'libpdfium_wrapper.so';

    final outLibFolder = Directory(
      join(input.packageRoot.toFilePath(), '.dart_tool', 'lib'),
    );
    if (!outLibFolder.existsSync()) {
      await outLibFolder.create(recursive: true);
    }
    // final libFile = File(join(outLibFolder.path, libName));

    if (targetOS == .linux) {
      await buildLinux(libName, input, output);
    } else if (targetOS == .android) {
      // await buildAndroid(input, output);
    }
    // await buildAllPlatfroms(input, output);
  });
}
