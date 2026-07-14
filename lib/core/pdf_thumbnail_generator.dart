// ignore_for_file: non_constant_identifier_names, avoid_print

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:than_pdf_engine/than_pdf_engine_bindings_generated.dart';

enum PdfThumbnailGeneratorImageType { jpg, png }

class PdfThumbnailGenerator {
  static PdfThumbnailGenerator instance = PdfThumbnailGenerator._();
  PdfThumbnailGenerator._();
  factory PdfThumbnailGenerator() => instance;

  Future<void>? _gateKeeper;
  Isolate? _isolate;
  SendPort? _backgroundSendPort;
  Timer? _keepAliveTimer;
  int _activeTasks = 0;
  final Duration timeoutDuration = Duration(seconds: 5);

  /// ### Generate Background Thread
  ///
  /// Thread Auto Close TimeOut -> `5s`
  ///
  Future<bool> generate(
    String pdfPath,
    String outPath, {
    bool overrideImage = false,
    int pageIndex = 0,
    String? password,
    int width = 0,
    int height = 0,
    int quality = 80,
    PdfThumbnailGeneratorImageType type = .jpg,
  }) async {
    // file ရှိနေရင် မ call တော့ဘူး
    if (!overrideImage && File(outPath).existsSync()) {
      return false;
    }
    _keepAliveTimer?.cancel();
    _activeTasks++;

    try {
      await _intiIsolate();
      print('[PdfThumbnailGenerator:_intiIsolate]: start background isolate]');
      final receivePort = ReceivePort();

      _backgroundSendPort?.send({
        'replyPort': receivePort.sendPort,
        'type': type,
        'quality': quality,
        'pdfPath': pdfPath,
        'outPath': outPath,
        'password': password ?? '',
        'width': width,
        'height': height,
        'pageIndex': pageIndex,
      });
      final res = await receivePort.first as bool;

      return res;
    } catch (e) {
      print('[PdfThumbnailGenerator:generate]: $e');
      return false;
    } finally {
      _activeTasks--;
      if (_activeTasks == 0) {
        _startKeepAliveTimer();
      }
    }
  }

  Future<void> _intiIsolate() async {
    if (_gateKeeper != null) {
      return _gateKeeper;
    }
    _gateKeeper = () async {
      final receive = ReceivePort();
      _isolate = await Isolate.spawn<SendPort>(
        _generateInBackground,
        (receive.sendPort),
      );
      _backgroundSendPort = await receive.first as SendPort;
    }();
    return _gateKeeper;
  }

  void _startKeepAliveTimer() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer(timeoutDuration, () {
      _killIsolate();
    });
  }

  void _killIsolate() async {
    print('[PdfThumbnailGenerator:_killIsolate]: close background isolate');
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _backgroundSendPort = null;
    _gateKeeper = null;
  }
}

Future<void> _generateInBackground(SendPort sendPort) async {
  final receive = ReceivePort();
  sendPort.send(receive.sendPort);
  pdfium_init();

  receive.listen((message) {
    try {
      if (message is Map) {
        final replyPort = message['replyPort'] as SendPort;
        final pdfPath = message['pdfPath'] as String;
        final outPath = message['outPath'] as String;
        final password = message['password'] as String;
        final width = message['width'] as int;
        final height = message['height'] as int;
        final quality = message['quality'] as int;
        final pageIndex = message['pageIndex'] as int;
        final type = message['type'] as PdfThumbnailGeneratorImageType;

        final pdf_path = pdfPath.toNativeUtf8();
        final out_path = outPath.toNativeUtf8();
        final password_ptr = password.toNativeUtf8();
        bool success = false;

        if (type == .jpg) {
          success = pdf_util_saveJpgWithIndex(
            pdf_path.cast<Char>(),
            password_ptr.cast<Char>(),
            out_path.cast<Char>(),
            pageIndex,
            width,
            height,
            quality,
          );
        } else if (type == .png) {
          success = pdf_util_savePngWithIndex(
            pdf_path.cast<Char>(),
            password_ptr.cast<Char>(),
            out_path.cast<Char>(),
            pageIndex,
            width,
            height,
          );
        }

        // free
        malloc.free(pdf_path);
        malloc.free(out_path);
        malloc.free(password_ptr);

        replyPort.send(success);
      }
    } catch (e) {
      print('[_generateInBackground]: $e');
    }
  });
}
