// ignore_for_file: unused_field, non_constant_identifier_names, public_member_api_docs, sort_constructors_first
// ignore_for_file: avoid_print

import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:than_pdf_engine/than_pdf_engine_bindings_generated.dart';

enum PdfWorkerCommand { stopWorker, getImage }

enum PdfWorkerRequestImageType { jpg, png }

class WorkerImageResponse {
  final double renderWidth;
  final double renderHeight;
  final TransferableTypedData trans;
  WorkerImageResponse({
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
  Future<void> run(String path) async {
    // PDF အသစ်ဖွင့်ရင် အရင် worker အဟောင်းကို စနစ်တကျ အရင်ပိတ်မယ်
    await stop();

    final receive = ReceivePort();
    _isolate = await Isolate.spawn<(SendPort, String)>(_backgroundPdfWorker, (
      receive.sendPort,
      path,
    ));
    _backgroundSendPort = await receive.first as SendPort?;
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
      _backgroundSendPort = null;
    }
    // Isolate.immediate နဲ့ သတ်မယ့်အစား သဘာဝအတိုင်း isolate ပိတ်သွားအောင် စောင့်ပါတယ်
    _isolate = null;
  }

  /// ### Get Page Image
  ///
  Future<WorkerImageResponse?> requestPageImage(
    int pageIndex, {
    required double width,
    required double height,
    int quality = 90,
    PdfWorkerRequestImageType type = .jpg,
  }) async {
    return await _requestPageImage(
      pageIndex,
      command: PdfWorkerCommand.getImage,
      width: width,
      height: height,
      quality: quality,
      imageType: type,
    );
  }

  /// @deprecated
  /// [requestPageImageJpg] အစား [requestPageImage] ကို အသုံးပြုပါ။
  @Deprecated(
    'Use requestPageImage instead. This method will be removed in future updates.',
  )
  Future<WorkerImageResponse?> requestPageImageJpg(
    int pageIndex, {
    required double width,
    required double height,
    int quality = 90,
  }) async {
    return await _requestPageImage(
      pageIndex,
      width: width,
      height: height,
      command: .getImage,
      imageType: .jpg,
    );
  }

  Future<WorkerImageResponse?> _requestPageImage(
    int pageIndex, {
    required double width,
    required double height,
    required PdfWorkerCommand command,
    PdfWorkerRequestImageType imageType = .jpg,
    int quality = 90,
  }) async {
    if (_backgroundSendPort == null) return null;
    final receive = ReceivePort();

    try {
      _backgroundSendPort?.send({
        'command': command,
        'imageType': imageType,
        'pageIndex': pageIndex,
        'width': width,
        'height': height,
        'quality': quality,
        'reply': receive.sendPort,
      });

      final res = await receive.first;
      receive.close();

      if (res is Map) {
        return WorkerImageResponse(
          renderWidth: res['width'] as double,
          renderHeight: res['height'] as double,
          trans: res['trans'] as TransferableTypedData,
        );
      }
      return null;
    } catch (e) {
      print('[PdfBackgroundWorker:requestPageImageJpg]: $e');
      receive.close();
      return null;
    }
  }

  /// ### Dispose Worker
  Future<void> dispose() async {
    await stop();
  }
}

Future<void> _backgroundPdfWorker((SendPort, String) args) async {
  final sendPort = args.$1;
  final path = args.$2;

  try {
    final receive = ReceivePort();
    sendPort.send(receive.sendPort);

    pdfium_init();

    final pdfCorePtr = pdf_core_create();
    final pathPtr = path.toNativeUtf8();
    pdf_core_openFile(pdfCorePtr, pathPtr.cast<Char>(), nullptr);
    calloc.free(pathPtr);

    // Queue တွက် လိုအပ်တဲ့ variable များ
    int? pendingPageIndex;
    SendPort? pendingReplyPort;
    double? pendingWidth;
    double? pendingHeight;
    int? pendingQuality;
    PdfWorkerRequestImageType imageType = .jpg;

    bool isProcessing = false;

    // Process Queue Function
    Future<void> processQueue() async {
      if (isProcessing || pendingPageIndex == null) return;

      isProcessing = true;

      // လက်ရှိလုပ်မယ့် အလုပ်ကို parameter ထုတ်ယူမယ်
      final pageIndex = pendingPageIndex!;
      final replyPort = pendingReplyPort!;
      final width = pendingWidth!;
      final height = pendingHeight!;
      final quality = pendingQuality!;

      // Queue ထဲက data ကို သုံးပြီးပြီဖြစ်လို့ reset လုပ်မယ်
      pendingPageIndex = null;
      pendingReplyPort = null;
      pendingWidth = null;
      pendingHeight = null;
      pendingQuality = null;

      try {
        final pagePtr = pdf_page_create(pdfCorePtr, pageIndex);

        final bufferSizePtr = calloc<Int>();
        Pointer<UnsignedChar> renderImageBuff = nullptr;

        if (imageType == .png) {
          // png
          renderImageBuff = pdf_page_renderToPngWH(
            pagePtr,
            bufferSizePtr,
            width.toInt(),
            height.toInt(),
          );
        } else {
          /// Native ဆီကနေ jpg image data pointer ယူမယ်
          renderImageBuff = pdf_page_renderToJpegWH(
            pagePtr,
            bufferSizePtr,
            width.toInt(),
            height.toInt(),
            quality,
          );
        }

        // Native memory ကို Dart Typed List အဖြစ် view လုပ်မယ်
        final rgbaBytes = renderImageBuff.cast<Uint8>().asTypedList(
          bufferSizePtr.value,
        );

        // Memory transfer မြန်စေရန် TransferableTypedData သုံးမယ်
        final trans = TransferableTypedData.fromList([rgbaBytes]);

        // Native Pointer များကို သန့်ရှင်းရေးလုပ်မယ်
        pdf_page_free_renderToJpegWH(renderImageBuff);
        pdf_page_destroy(pagePtr);
        calloc.free(bufferSizePtr);

        // Main thread ဆီကို width, height တွေပါ ထည့်ပြီး Map အနေနဲ့ ပို့ပေးမယ်
        replyPort.send({'width': width, 'height': height, 'trans': trans});
      } catch (e) {
        print('[render:error]: $e');
        replyPort.send(null);
      } finally {
        isProcessing = false;
        // နောက်ထပ် Request ကျန်ခဲ့ရင် ချက်ချင်း စစ်ဆေးပြီး ထပ် run မယ်
        Future.microtask(() => processQueue());
      }
    }

    receive.listen((msg) {
      if (msg is Map) {
        final command = msg['command'] as PdfWorkerCommand;

        // 1. Stop Worker Command
        if (command == PdfWorkerCommand.stopWorker) {
          final reply = msg['reply'] as SendPort;

          // ကျန်နေသေးတဲ့ pending request ရှိရင် null ပြန်ပေးပြီး ရှင်းထုတ်မယ်
          if (pendingReplyPort != null) {
            pendingReplyPort!.send(null);
          }

          pdf_core_destroy(pdfCorePtr);
          reply.send(null);
          receive.close(); // Port ကို ပိတ်ပြီး isolate ကို ရပ်တန့်စေမယ်
          return;
        }

        // 2. Get JPG Image Command
        if (command == PdfWorkerCommand.getImage) {
          imageType = msg['imageType'] as PdfWorkerRequestImageType;

          final reply = msg['reply'] as SendPort;

          // **ဒီနေရာက အရေးကြီးဆုံးပြင်ဆင်မှုဖြစ်ပါတယ်**
          // လက်ရှိ queue ထဲမှာ အလုပ်တစ်ခု စောင့်နေတုန်း (သို့မဟုတ်) အလုပ်လုပ်နေတုန်းမှာ
          // အလုပ်အသစ် ထပ်ဝင်လာရင် အရင်လူကို Freeze မဖြစ်သွားအောင် ချက်ချင်း null ပြန်ပေးရပါမယ်။
          if (pendingReplyPort != null && pendingReplyPort != reply) {
            pendingReplyPort!.send(null);
          }

          // Request အသစ်ကို Queue variable တွေထဲ ထည့်လိုက်မယ်
          pendingPageIndex = msg['pageIndex'] as int;
          pendingReplyPort = reply;
          pendingWidth = msg['width'] as double;
          pendingHeight = msg['height'] as double;
          pendingQuality = msg['quality'] as int;

          // Queue ကို စတင် run မယ်
          processQueue();
        }
      }
    });
  } catch (e) {
    print('[_backgroundPdfWorker:error]: $e');
  }
}
