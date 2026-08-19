// ignore_for_file: avoid_print

import 'dart:isolate';
import 'dart:typed_data';

import 'package:than_pdf_engine/core/low_level_api/index.dart';
import 'package:than_pdf_engine/core/types/result.dart';
import 'package:than_pdf_engine/than_pdf_engine.dart';

part 'pdf_reader_background_worker.dart';

class PdfReaderWorker {
  Isolate? _isolate;
  SendPort? _workerPort;

  /// open pdf doc file
  ///
  /// if `error` -> it will call auto close
  ///
  ///```dart
  /// final reader = PdfReaderWorker();
  ///
  /// final res = await reader.open(path);
  ///
  /// if (res.isErr) {
  ///   print('open Error: ${res.unwrapError().status}');
  ///   return;
  /// }
  /// print('wait 3 sec');
  /// await Future.delayed(Duration(seconds: 3));
  /// await reader.close();
  /// ```
  Future<Result<bool, PdfReaderWorkerOpenErrorResult>> open(String path) async {
    final rec = ReceivePort();
    try {
      _isolate = await Isolate.spawn<(SendPort, String)>(_backgroundWorker, (
        rec.sendPort,
        path,
      ));
      final map = await rec.first as Map;
      final result = map['result'] as PdfReaderWorkerResult;

      if (result == .error) {
        // close isolate
        _isolate?.kill();
        final status = map['status'] as PdfiumStatus;
        final message = map['message'] as String;
        return Err(.new(message: message, status: status));
      }

      if (result == .success) {
        // success
        _workerPort = map['workerPort'] as SendPort;

        print('[PdfReaderWorker:open]: opened - `$path`');

        return Ok(true);
      }
      // unknow error
      _isolate?.kill();
      print('[PdfReaderWorker:open]: `Unknown Error`');
      return Err(.new(message: 'Unknown Error'));
    } catch (e) {
      print('[PdfReaderWorker:open]: error - `$e`');
      return Err(.new(message: e.toString()));
    } finally {
      rec.close();
    }
  }

  Future<Result<List<PageSize>, String>> getAllPageSizes() async {
    final workerPort = _workerPort;

    if (workerPort == null) {
      return Err('PDF reader is not opened');
    }

    final rec = ReceivePort();
    try {
      workerPort.send({
        'reply': rec.sendPort,
        'command': PdfReaderWorkerCommand.getPageSize,
      });

      final map = await rec.first as Map;
      final result = map['result'] as PdfReaderWorkerResult;

      if (result == .error) {
        final message = map['message'] as String;
        return Err(message);
      }
      if (result == .success) {
        final rawList = map['list'] as List;
        final list = <PageSize>[];
        for (var p in rawList) {
          list.add(
            .new(page: p[0], width: p[1] as double, height: p[2] as double),
          );
        }
        return Ok(list);
      }

      return Err('Unknown Error!');
    } catch (e) {
      return Err(e.toString());
    } finally {
      rec.close();
    }
  }

  ///
  /// Usage
  ///```dart
  ///  if (imageRes.isErr) {
  ///   print('image Error: ${imageRes.unwrapError()}');
  /// } else {
  ///   // data
  ///   print('image: ${imageRes.unwrap()}');
  /// }
  /// ```
  Future<Result<Uint8List, String>> getImage(
    int pageIndex, {
    int targetWidth = 0,
    int targetHeight = 0,
    int quality = 100,
    PageRenderImageType renderImageType = .jpg,
  }) async {
    final workerPort = _workerPort;

    if (workerPort == null) {
      return Err('PDF reader is not opened');
    }

    final rec = ReceivePort();
    try {
      workerPort.send({
        'reply': rec.sendPort,
        'command': PdfReaderWorkerCommand.genImage,
        'pageIndex': pageIndex,
        'quality': quality,
        'targetWidth': targetWidth,
        'targetHeight': targetHeight,
        'renderImageType': renderImageType,
      });

      final map = await rec.first as Map;
      final result = map['result'] as PdfReaderWorkerResult;

      if (result == .error) {
        final message = map['message'] as String;
        return Err(message);
      }
      if (result == .success) {
        final data = map['data'] as TransferableTypedData;
        return Ok(data.materialize().asUint8List());
      }

      return Err('Unknown Error!');
    } catch (e) {
      return Err(e.toString());
    } finally {
      rec.close();
    }
  }

  Future<void> close() async {
    final workerPort = _workerPort;

    if (workerPort == null) {
      _isolate?.kill();
      _isolate = null;
      return;
    }
    final rec = ReceivePort();

    workerPort.send({
      'reply': rec.sendPort,
      'command': PdfReaderWorkerCommand.close,
    });

    try {
      // await rec.first.timeout(const Duration(seconds: 5));
    } finally {
      rec.close();

      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
      _workerPort = null;

      print('[PdfReaderWorker:close]: Isolate Closed');
    }
  }
}
