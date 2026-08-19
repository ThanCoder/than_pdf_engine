// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:isolate';

import 'package:than_pdf_engine/core/low_level_api/pdf_document.dart';
import 'package:than_pdf_engine/core/types/result.dart';
import 'package:than_pdf_engine/than_pdf_engine.dart';

part 'pdf_image_generator_worker.dart';

class PdfImageGenerator {
  static final PdfImageGenerator instance = PdfImageGenerator._();
  PdfImageGenerator._();
  factory PdfImageGenerator() => instance;

  void setAutoCloseTimer(Duration autoCloseIsolateDuration) {
    _autoCloseIsolateDuration = autoCloseIsolateDuration;
  }

  int _activeGenerateCount = 0;

  /// PDF Page Image Generator
  ///
  /// `targetWidth`=0 -> original size
  ///
  /// `targetHeight`=0 -> original size
  Future<Result<bool, String>> generate(
    String pdfPath, {
    required String outPath,
    int pageIndex = 0,
    int quality = 100,
    PageRenderImageType renderImageType = .jpg,
    int targetWidth = 300,
    int targetHeight = 300,
  }) async {
    final rec = ReceivePort();
    try {
      _activeGenerateCount++;
      _autoCloseTimer?.cancel();
      _autoCloseTimer = null;

      await _initialized();

      _workerPort!.send({
        'reply': rec.sendPort,
        'command': PdfImageGeneratorWorkerCommand.generate,
        'path': pdfPath,
        'outPath': outPath,
        'pageIndex': pageIndex,
        'quality': quality,
        'targetWidth': targetWidth,
        'targetHeight': targetHeight,
        'renderImage': renderImageType,
      });
      final map = await rec.first as Map;

      //auto close timer
      _autoClose();

      final result = map['result'] as PdfImageGeneratorWorkerResult;
      final message = map['message'] as String;

      if (result == .success) {
        return Ok(true);
      }
      if (result == .error) {
        return Err(message);
      }
      return Err('Result: ${result.name}');
    } catch (e) {
      return Err(e.toString());
    } finally {
      rec.close();

      _activeGenerateCount--;

      if (_activeGenerateCount == 0) {
        _autoClose();
      }
    }
  }

  Isolate? _isolate;
  SendPort? _workerPort;
  Completer<void>? _initCompleter;
  Duration _autoCloseIsolateDuration = Duration(seconds: 5);

  Future<void> _initialized() async {
    if (_initCompleter != null) {
      return await _initCompleter!.future;
    }
    final completer = _initCompleter = Completer<void>();
    try {
      await _initIsolate();
      print('[PdfImageGenerator:_initialized]: Initalized Isolate');
      completer.complete();
    } catch (e) {
      completer.completeError(e);
      rethrow;
    }

    return completer.future;
  }

  Future<void> _initIsolate() async {
    final rec = ReceivePort();
    _isolate = await Isolate.spawn(_pdfImageGeneratorWorker, rec.sendPort);
    _workerPort = await rec.first as SendPort;
    rec.close();
  }

  // timer
  Timer? _autoCloseTimer;
  void _autoClose() {
    _autoCloseTimer?.cancel();

    if (_activeGenerateCount != 0) {
      return;
    }

    _autoCloseTimer = Timer(_autoCloseIsolateDuration, () {
      if (_activeGenerateCount == 0) {
        close();
      }
    });
  }

  /// Auto Close
  Future<void> close() async {
    _autoCloseTimer?.cancel();
    _autoCloseTimer = null;

    final workerPort = _workerPort;

    if (workerPort == null) {
      _isolate?.kill();
      _isolate = null;
      _initCompleter = null;
      return;
    }

    final rec = ReceivePort();

    workerPort.send({
      'reply': rec.sendPort,
      'command': PdfImageGeneratorWorkerCommand.close,
    });

    try {
      await rec.first.timeout(const Duration(seconds: 5));
    } finally {
      rec.close();

      _isolate?.kill();
      _isolate = null;
      _workerPort = null;
      _initCompleter = null;

      print('[PdfImageGenerator:close]: Isolate Closed');
    }
  }
}
