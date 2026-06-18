// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: avoid_print

import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'package:than_pdf_engine/than_pdf_engine_bindings_generated.dart';

enum PdfWorkerCommand { stopWorker, getRgbaImage, getRgbaImageLowQuality }

class WrokerImageResponse {
  final double renderWidth;
  final double renderHeight;
  final TransferableTypedData trans;
  WrokerImageResponse({
    required this.renderWidth,
    required this.renderHeight,
    required this.trans,
  });
}

class PdfBackgroundWorker {
  static PdfBackgroundWorker instance = PdfBackgroundWorker._();
  PdfBackgroundWorker._();
  factory PdfBackgroundWorker() => instance;

  Isolate? _isolate;
  SendPort? _backgroundSendPort;

  Future<void> run(String path) async {
    await stop();

    final receive = ReceivePort();
    _isolate = await Isolate.spawn<(SendPort, String)>(_backgroundPdfWroker, (
      receive.sendPort,
      path,
    ));
    _backgroundSendPort = await receive.first;
    receive.close();
  }

  Future<void> stop() async {
    if (_backgroundSendPort != null) {
      final receive = ReceivePort();
      _backgroundSendPort!.send({
        'command': PdfWorkerCommand.stopWorker,
        'reply': receive.sendPort,
      });
      await receive.first;
    }
    _isolate?.kill(priority: Isolate.immediate);
    _backgroundSendPort = null;
  }

  // Future<TransferableTypedData?> requestPageImageRgba(int pageIndex) async {
  //   final receive = ReceivePort();
  //   try {
  //     _backgroundSendPort?.send({
  //       'command': PdfWorkerCommand.getRgbaImage,
  //       'pageIndex': pageIndex,
  //       'reply': receive.sendPort,
  //     });
  //     final res = await receive.first;
  //     receive.close();
  //     if (res is Map) {
  //       return res['data'] as TransferableTypedData;
  //     }
  //     // print('map is ${res.runtimeType}');
  //     return null;
  //   } catch (e) {
  //     receive.close();
  //     return null;
  //   }
  // }

  ///### (TransferableTypedData,renderWidth,renderHeight)
  Future<WrokerImageResponse?> requestPageImageJpgQuality(
    int pageIndex, {
    required double deviceWidth,
    double zoomFactor = 1,
    int quality = 90,
  }) async {
    final receive = ReceivePort();
    try {
      _backgroundSendPort?.send({
        'command': PdfWorkerCommand.getRgbaImageLowQuality,
        'pageIndex': pageIndex,
        'zoomFactor': zoomFactor,
        'deviceWidth': deviceWidth,
        'quality': quality,
        'reply': receive.sendPort,
      });
      final res = await receive.first;
      receive.close();

      if (res is Map) {
        return WrokerImageResponse(
          renderWidth: res['renderWidth'] as double,
          renderHeight: res['renderHeight'] as double,
          trans: res['data'] as TransferableTypedData,
        );
      }
      // print('map is ${res.runtimeType}');
      return null;
    } catch (e) {
      print('[PdfBackgroundWorker:requestPageImageRgbaLowQuality]: $e');
      receive.close();
      return null;
    }
  }

  Future<void> dispose() async {
    await stop();
  }
}

Future<void> _backgroundPdfWroker((SendPort, String) args) async {
  final sendPort = args.$1;
  final path = args.$2;
  try {
    final receive = ReceivePort();
    sendPort.send(receive.sendPort);

    final pdf = pdf_core_create();
    final pathPtr = path.toNativeUtf8();
    pdf_core_openFile(pdf, pathPtr.cast<Char>(), nullptr);

    // လက်ရှိ Render လုပ်ဖို့ တန်းစီနေတဲ့ (နောက်ဆုံးဝင်လာတဲ့) Page Index ကို မှတ်ရန်
    int? pendingPageIndex;
    SendPort? pendingReplyPort;
    bool isProcessing = false;

    void processQueue(
      double zoomFactor,
      double deviceWidth,
      int quality,
    ) async {
      if (isProcessing || pendingPageIndex == null) return;

      isProcessing = true;

      final pageIndex = pendingPageIndex!;
      final replyPort = pendingReplyPort!;

      // သုံးပြီးသား variable တွေကို ရှင်းထုတ်
      pendingPageIndex = null;
      pendingReplyPort = null;

      try {
        final page = pdf_core_getPage(pdf, pageIndex);
        final bufferSizePtr = calloc<Int>();
        // final rgbaPtr = pdf_page_renderToRGBA(page, zoomFactor, bufferSizePtr);
        final rgbaPtr = pdf_page_renderToJpeg(
          page,
          bufferSizePtr,
          deviceWidth.toInt(),
          zoomFactor,
          quality,
        );
        final renderWidth = pdf_page_getRenderWidth(page, zoomFactor);
        final renderHeight = pdf_page_getRenderHeight(page, zoomFactor);
        final rgbaBytes = rgbaPtr.asTypedList(bufferSizePtr.value);

        final dartBytes = Uint8List.fromList(rgbaBytes);
        final trans = TransferableTypedData.fromList([dartBytes]);

        pdf_page_destroy(page);
        pdf_page_free_render_data(rgbaPtr);
        calloc.free(bufferSizePtr);

        replyPort.send({
          'renderWidth': renderWidth.toDouble(),
          'renderHeight': renderHeight.toDouble(),
          'data': trans,
        });
      } catch (e) {
        print('[render:error]: $e');
        replyPort.send(null); // error ဖြစ်ရင်လည်း UI ကို null ပြန်ပေးရမယ်
      }

      isProcessing = false;

      // နောက်ထပ်ကျန်တဲ့ Request အသစ်ကို ဆက်လုပ်
      processQueue(zoomFactor, deviceWidth, quality);
    }

    receive.listen((msg) {
      // message
      if (msg is Map) {
        final command = msg['command'] as PdfWorkerCommand;
        // Stop
        if (command == .stopWorker) {
          final reply = msg['reply'] as SendPort;
          print('close pdf');
          pdf_core_destroy(pdf);
          reply.send(null);
        }

        // RGBA image Low Quality
        if (command == .getRgbaImageLowQuality) {
          final zoomFactor = msg['zoomFactor'] as double;
          final deviceWidth = msg['deviceWidth'] as double;
          final quality = msg['quality'] as int;

          if (pendingReplyPort != null && pendingReplyPort != msg['reply']) {
            pendingReplyPort!.send(
              null,
            ); // အရင်ကောင်ကို Skip ကြောင်း UI ဆီ အကြောင်းကြား
          }

          pendingPageIndex = msg['pageIndex'] as int;
          pendingReplyPort = msg['reply'] as SendPort;

          processQueue(zoomFactor, deviceWidth, quality);
        }
      }
    });
  } catch (e) {
    print('[_backgroundPdfWroker:error]: $e');
  }
}
