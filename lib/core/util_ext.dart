import 'dart:io';

extension PExt on String {
  String join(String path) {
    return '$this${Platform.pathSeparator}$path';
  }
}
