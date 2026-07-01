// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: avoid_print

import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'package:than_pdf_engine/than_pdf_engine_bindings_generated.dart';

enum PdfWorkerCommand { stopWorker, getJpgImage }

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
  static PdfBackgroundWorker? _instance;

  /// ### Singleton
  static PdfBackgroundWorker get getInstance {
    _instance ??= PdfBackgroundWorker();
    return _instance!;
  }

  Isolate? _isolate;
  SendPort? _backgroundSendPort;

  /// ### Worker Initialize
  ///
  /// when if you do not use -> you should call [stop,dispose] method
  ///
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

  /// ### Stop Worker
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

  /// ### Get Page Image
  Future<TransferableTypedData?> requestPageImageJpg(
    int pageIndex, {
    required double width,
    required double height,
    int quality = 90,
  }) async {
    if (_backgroundSendPort == null) return null;
    final receive = ReceivePort();
    try {
      _backgroundSendPort?.send({
        'command': PdfWorkerCommand.getJpgImage,
        'pageIndex': pageIndex,
        'width': width,
        'height': height,
        'quality': quality,
        'reply': receive.sendPort,
      });
      final res = await receive.first;
      receive.close();

      if (res is TransferableTypedData) {
        return res;
      }
      // print('map is ${res.runtimeType}');
      return null;
    } catch (e) {
      print('[PdfBackgroundWorker:requestPageImageRgbaLowQuality]: $e');
      receive.close();
      return null;
    }
  }

  /// ### Stop Worker
  Future<void> dispose() async {
    await stop();
  }
}

/// run in background
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

    void processQueue(double width, double height, int quality) async {
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
        final rgbaPtr = pdf_page_renderToJpegWH(
          page,
          bufferSizePtr,
          width.toInt(),
          height.toInt(),
          quality,
        );
        final rgbaBytes = rgbaPtr.asTypedList(bufferSizePtr.value);

        final dartBytes = Uint8List.fromList(rgbaBytes);
        // print('data size: ${dartBytes.length}');
        final trans = TransferableTypedData.fromList([dartBytes]);

        pdf_page_destroy(page);
        pdf_page_free_render_data(rgbaPtr);
        calloc.free(bufferSizePtr);

        replyPort.send(trans);
      } catch (e) {
        print('[render:error]: $e');
        replyPort.send(null); // error ဖြစ်ရင်လည်း UI ကို null ပြန်ပေးရမယ်
      }

      isProcessing = false;

      // နောက်ထပ်ကျန်တဲ့ Request အသစ်ကို ဆက်လုပ်
      processQueue(width, height, quality);
    }

    receive.listen((msg) {
      // message
      if (msg is Map) {
        final command = msg['command'] as PdfWorkerCommand;
        // Stop
        if (command == .stopWorker) {
          final reply = msg['reply'] as SendPort;
          // print('close pdf');
          pdf_core_destroy(pdf);
          reply.send(null);
        }

        // RGBA image Low Quality
        if (command == .getJpgImage) {
          final width = msg['width'] as double;
          final height = msg['height'] as double;
          final quality = msg['quality'] as int;

          if (pendingReplyPort != null && pendingReplyPort != msg['reply']) {
            pendingReplyPort!.send(
              null,
            ); // အရင်ကောင်ကို Skip ကြောင်း UI ဆီ အကြောင်းကြား
          }

          pendingPageIndex = msg['pageIndex'] as int;
          pendingReplyPort = msg['reply'] as SendPort;

          processQueue(width, height, quality);
        }
      }
    });
  } catch (e) {
    print('[_backgroundPdfWroker:error]: $e');
  }
}
