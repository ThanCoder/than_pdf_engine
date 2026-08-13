// ignore_for_file: unused_field, non_constant_identifier_names
// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:than_pdf_engine/than_pdf_engine_bindings_generated.dart';

part 'pdf_worker.dart';

class PdfBackgroundWorker {
  static PdfBackgroundWorker? _instance;

  static PdfBackgroundWorker get getInstance {
    _instance ??= PdfBackgroundWorker();
    return _instance!;
  }

  Isolate? _isolate;
  SendPort? _backgroundSendPort;

  bool _starting = false;

  // ------------------------------------------------------------
  // Run
  // ------------------------------------------------------------

  Future<void> run(String path) async {
    if (_starting) {
      return;
    }

    _starting = true;

    try {
      await stop();

      final receive = ReceivePort();

      try {
        final isolate = await Isolate.spawn<(SendPort, String)>(
          _backgroundPdfWorker,
          (
            receive.sendPort,
            path,
          ),
        );

        _isolate = isolate;

        final firstMessage = await receive.first;

        if (firstMessage is! SendPort) {
          throw StateError(
            'PDF worker initialization failed: $firstMessage',
          );
        }

        _backgroundSendPort = firstMessage;
      } catch (e, st) {
        print('[PdfBackgroundWorker:run] $e');
        print(st);

        _isolate?.kill(
          priority: Isolate.immediate,
        );

        _isolate = null;
        _backgroundSendPort = null;

        rethrow;
      } finally {
        receive.close();
      }
    } finally {
      _starting = false;
    }
  }

  // ------------------------------------------------------------
  // Stop
  // ------------------------------------------------------------

  Future<void> stop() async {
    final sendPort = _backgroundSendPort;
    final isolate = _isolate;

    if (sendPort == null) {
      isolate?.kill(
        priority: Isolate.immediate,
      );

      _isolate = null;
      _backgroundSendPort = null;

      return;
    }

    final receive = ReceivePort();

    try {
      sendPort.send({
        'command': PdfWorkerCommand.stopWorker,
        'reply': receive.sendPort,
      });

      // Worker က current render ပြီးမှ reply ပြန်မယ်
      await receive.first;
    } catch (e, st) {
      print('[PdfBackgroundWorker:stop] $e');
      print(st);

      // Worker က reply မပြန်နိုင်တဲ့အခြေအနေမှာ
      // isolate ကို force kill
      isolate?.kill(
        priority: Isolate.immediate,
      );
    } finally {
      receive.close();

      _backgroundSendPort = null;
      _isolate = null;
    }
  }

  // ------------------------------------------------------------
  // Request Page Image
  // ------------------------------------------------------------

  Future<WorkerImageResponse?> requestPageImage(
    int pageIndex, {
    required double width,
    required double height,
    int quality = 90,
    PdfWorkerRequestImageType type =
        PdfWorkerRequestImageType.jpg,
  }) {
    return _requestPageImage(
      pageIndex,
      command: PdfWorkerCommand.getImage,
      width: width,
      height: height,
      quality: quality,
      imageType: type,
    );
  }

  @Deprecated(
    'Use requestPageImage instead.',
  )
  Future<WorkerImageResponse?> requestPageImageJpg(
    int pageIndex, {
    required double width,
    required double height,
    int quality = 90,
  }) {
    return _requestPageImage(
      pageIndex,
      width: width,
      height: height,
      command: PdfWorkerCommand.getImage,
      imageType: PdfWorkerRequestImageType.jpg,
      quality: quality,
    );
  }

  // ------------------------------------------------------------
  // Internal Request
  // ------------------------------------------------------------

  Future<WorkerImageResponse?> _requestPageImage(
    int pageIndex, {
    required double width,
    required double height,
    required PdfWorkerCommand command,
    PdfWorkerRequestImageType imageType =
        PdfWorkerRequestImageType.jpg,
    int quality = 90,
  }) async {
    final sendPort = _backgroundSendPort;

    if (sendPort == null) {
      print(
        '[PdfBackgroundWorker] Worker is not running.',
      );
      return null;
    }

    final receive = ReceivePort();

    try {
      sendPort.send({
        'command': command,
        'imageType': imageType,
        'pageIndex': pageIndex,
        'width': width,
        'height': height,
        'quality': quality,
        'reply': receive.sendPort,
      });

      final result = await receive.first;

      if (result is! Map) {
        return null;
      }

      final renderWidth = result['width'];
      final renderHeight = result['height'];
      final trans = result['trans'];

      if (renderWidth is! double ||
          renderHeight is! double ||
          trans is! TransferableTypedData) {
        return null;
      }

      return WorkerImageResponse(
        renderWidth: renderWidth,
        renderHeight: renderHeight,
        trans: trans,
      );
    } catch (e, st) {
      print(
        '[PdfBackgroundWorker:requestPageImage] $e',
      );
      print(st);

      return null;
    } finally {
      receive.close();
    }
  }

  // ------------------------------------------------------------
  // Dispose
  // ------------------------------------------------------------

  Future<void> dispose() async {
    await stop();
  }
}