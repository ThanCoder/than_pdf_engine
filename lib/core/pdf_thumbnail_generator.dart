// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:than_pdf_engine/than_pdf_engine_bindings_generated.dart';

enum PdfThumbnailGeneratorImageType { jpg, png }

class PdfThumbnailGenerator {
  static final PdfThumbnailGenerator instance = PdfThumbnailGenerator._();

  PdfThumbnailGenerator._();

  factory PdfThumbnailGenerator() => instance;

  Future<void>? _gateKeeper;

  Isolate? _isolate;
  SendPort? _backgroundSendPort;

  Timer? _keepAliveTimer;

  int _activeTasks = 0;

  final Duration timeoutDuration = const Duration(seconds: 5);

  Future<bool> generate(
    String pdfPath,
    String outPath, {
    bool overrideImage = false,
    int pageIndex = 0,
    String? password,
    int width = 0,
    int height = 0,
    int quality = 80,
    PdfThumbnailGeneratorImageType type = PdfThumbnailGeneratorImageType.jpg,
  }) async {
    // File already exists.
    if (!overrideImage && File(outPath).existsSync()) {
      return false;
    }

    _keepAliveTimer?.cancel();
    _activeTasks++;

    final replyPort = ReceivePort();

    try {
      await _initIsolate();

      // print(
      //   '[PdfThumbnailGenerator:generate] '
      //   'send request -> $pdfPath',
      // );

      _backgroundSendPort!.send({
        'replyPort': replyPort.sendPort,
        'type': type,
        'quality': quality,
        'pdfPath': pdfPath,
        'outPath': outPath,
        'password': password ?? '',
        'width': width,
        'height': height,
        'pageIndex': pageIndex,
      });

      final result = await replyPort.first;

      return result == true;
    } catch (e, st) {
      // ignore: avoid_print
      print('[PdfThumbnailGenerator:generate] $e');
      // ignore: avoid_print
      print(st);

      return false;
    } finally {
      replyPort.close();

      _activeTasks--;

      if (_activeTasks == 0) {
        _startKeepAliveTimer();
      }
    }
  }

  Future<void> _initIsolate() async {
    // Already initialized.
    final gateKeeper = _gateKeeper;

    if (gateKeeper != null) {
      await gateKeeper;
      return;
    }

    final receivePort = ReceivePort();

    final future = _spawnIsolate(receivePort);

    _gateKeeper = future;

    try {
      await future;
    } catch (_) {
      // Important:
      // If spawn/init fails, allow the next request
      // to create a fresh isolate.
      _gateKeeper = null;
      rethrow;
    } finally {
      receivePort.close();
    }
  }

  Future<void> _spawnIsolate(ReceivePort receivePort) async {
    final isolate = await Isolate.spawn<SendPort>(
      _generateInBackground,
      receivePort.sendPort,
    );

    _isolate = isolate;

    try {
      final port = await receivePort.first;

      if (port is! SendPort) {
        throw StateError(
          'PdfThumbnailGenerator worker did not return SendPort',
        );
      }

      _backgroundSendPort = port;
    } catch (e) {
      isolate.kill(priority: Isolate.immediate);

      _isolate = null;
      _backgroundSendPort = null;

      rethrow;
    }
  }

  void _startKeepAliveTimer() {
    _keepAliveTimer?.cancel();

    _keepAliveTimer = Timer(timeoutDuration, () {
      if (_activeTasks == 0) {
        _killIsolate();
      }
    });
  }

  Future<void> _killIsolate() async {
    if (_isolate == null) {
      return;
    }

    // print(
    //   '[PdfThumbnailGenerator:_killIsolate] '
    //   'close background isolate',
    // );

    final worker = _backgroundSendPort;

    if (worker != null) {
      final replyPort = ReceivePort();

      try {
        worker.send({'command': 'dispose', 'replyPort': replyPort.sendPort});

        // Wait until pdfium_destroy() is completed.
        await replyPort.first.timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        );
      } catch (e) {
        // ignore: avoid_print
        print(
          '[PdfThumbnailGenerator:_killIsolate] '
          'dispose error: $e',
        );
      } finally {
        replyPort.close();
      }
    }

    // Fallback.
    _isolate?.kill(priority: Isolate.immediate);

    _isolate = null;
    _backgroundSendPort = null;
    _gateKeeper = null;
  }

  Future<void> dispose() async {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;

    await _killIsolate();
  }
}

// ---------------------------------------------------------------------------
// Background worker
// ---------------------------------------------------------------------------

Future<void> _generateInBackground(SendPort sendPort) async {
  final receivePort = ReceivePort();

  // Return worker SendPort to main isolate.
  sendPort.send(receivePort.sendPort);

  // print('[PdfThumbnailWorker] pdfium_init()');

  pdfium_init();

  try {
    // IMPORTANT:
    //
    // await for guarantees that requests are processed
    // one by one.
    //
    // PDFium will NOT receive multiple thumbnail requests
    // concurrently from this worker.
    await for (final message in receivePort) {
      if (message is! Map) {
        continue;
      }

      final command = message['command'];

      // ---------------------------------------------------------
      // Dispose
      // ---------------------------------------------------------

      if (command == 'dispose') {
        final replyPort = message['replyPort'] as SendPort?;

        // ignore: avoid_print
        print('[PdfThumbnailWorker] pdfium_destroy()');

        try {
          pdfium_destroy();
        } catch (e) {
          // ignore: avoid_print
          print(
            '[PdfThumbnailWorker] '
            'pdfium_destroy error: $e',
          );
        }

        replyPort?.send(true);

        break;
      }

      // ---------------------------------------------------------
      // Generate
      // ---------------------------------------------------------

      final replyPort = message['replyPort'] as SendPort?;

      if (replyPort == null) {
        continue;
      }

      try {
        final pdfPath = message['pdfPath'] as String;
        final outPath = message['outPath'] as String;
        final password = message['password'] as String;

        final width = message['width'] as int;
        final height = message['height'] as int;

        final quality = message['quality'] as int;
        final pageIndex = message['pageIndex'] as int;

        final type = message['type'] as PdfThumbnailGeneratorImageType;

        // print(
        //   '[PdfThumbnailWorker] '
        //   'generate: $pdfPath',
        // );

        final pdf_path = pdfPath.toNativeUtf8();
        final out_path = outPath.toNativeUtf8();
        final password_ptr = password.toNativeUtf8();

        bool success = false;

        try {
          switch (type) {
            case PdfThumbnailGeneratorImageType.jpg:
              success = pdf_util_saveJpgWithIndex(
                pdf_path.cast<Char>(),
                password_ptr.cast<Char>(),
                out_path.cast<Char>(),
                pageIndex,
                width,
                height,
                quality,
              );

            case PdfThumbnailGeneratorImageType.png:
              success = pdf_util_savePngWithIndex(
                pdf_path.cast<Char>(),
                password_ptr.cast<Char>(),
                out_path.cast<Char>(),
                pageIndex,
                width,
                height,
              );
          }
        } finally {
          malloc.free(pdf_path);
          malloc.free(out_path);
          malloc.free(password_ptr);
        }

        // print(
        //   '[PdfThumbnailWorker] '
        //   'finished: $success',
        // );

        replyPort.send(success);
      } catch (e, st) {
        // ignore: avoid_print
        print(
          '[PdfThumbnailWorker] '
          'generate error: $e',
        );

        // ignore: avoid_print
        print(st);

        // IMPORTANT:
        //
        // Never leave the caller waiting for replyPort.first.
        replyPort.send(false);
      }
    }
  } catch (e, st) {
    // ignore: avoid_print
    print('[PdfThumbnailWorker] fatal error: $e');
    // ignore: avoid_print
    print(st);
  } finally {
    receivePort.close();
  }

  // ignore: avoid_print
  print('[PdfThumbnailWorker] exited');
}
