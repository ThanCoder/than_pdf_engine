// ignore_for_file: avoid_print

part of 'pdf_background_worker.dart';

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

Future<void> _backgroundPdfWorker((SendPort, String) args) async {
  final mainSendPort = args.$1;
  final path = args.$2;

  final receive = ReceivePort();

  Pointer<pdf_core_s> pdfCorePtr = nullptr;

  bool stopping = false;

  // Current render ကို ကိုင်ထားမယ့် Future
  Future<void>? processing;

  // ------------------------------------------------------------
  // Pending request
  // ------------------------------------------------------------

  int? pendingPageIndex;
  double? pendingWidth;
  double? pendingHeight;
  int? pendingQuality;
  PdfWorkerRequestImageType? pendingImageType;
  SendPort? pendingReply;

  try {
    // ----------------------------------------------------------
    // Tell main isolate worker is ready
    // ----------------------------------------------------------

    mainSendPort.send(receive.sendPort);

    // ----------------------------------------------------------
    // PDFium init
    // ----------------------------------------------------------

    pdfium_init();

    // ----------------------------------------------------------
    // Create PDF Core
    // ----------------------------------------------------------

    pdfCorePtr = pdf_core_create();

    if (pdfCorePtr == nullptr) {
      throw StateError('pdf_core_create() returned nullptr.');
    }

    // ----------------------------------------------------------
    // Open PDF
    // ----------------------------------------------------------

    final pathPtr = path.toNativeUtf8();

    try {
      pdf_core_openFile(pdfCorePtr, pathPtr.cast<Char>(), nullptr);
    } finally {
      calloc.free(pathPtr);
    }

    // ----------------------------------------------------------
    // Process
    // ----------------------------------------------------------

    Future<void> processQueue() async {
      if (stopping) {
        return;
      }

      if (processing != null) {
        return;
      }

      if (pendingReply == null ||
          pendingPageIndex == null ||
          pendingWidth == null ||
          pendingHeight == null ||
          pendingQuality == null ||
          pendingImageType == null) {
        return;
      }

      // --------------------------------------------------------
      // Take pending request
      // --------------------------------------------------------

      final reply = pendingReply!;
      final pageIndex = pendingPageIndex!;
      final width = pendingWidth!;
      final height = pendingHeight!;
      final quality = pendingQuality!;
      final imageType = pendingImageType!;

      // --------------------------------------------------------
      // Clear pending
      // --------------------------------------------------------

      pendingReply = null;
      pendingPageIndex = null;
      pendingWidth = null;
      pendingHeight = null;
      pendingQuality = null;
      pendingImageType = null;

      // --------------------------------------------------------
      // Current processing
      // --------------------------------------------------------

      late Future<void> current;

      current = _renderPage(
        pdfCorePtr: pdfCorePtr,
        pageIndex: pageIndex,
        width: width,
        height: height,
        quality: quality,
        imageType: imageType,
        reply: reply,
      );

      processing = current;

      try {
        await current;
      } finally {
        if (identical(processing, current)) {
          processing = null;
        }
      }

      // --------------------------------------------------------
      // Next pending request
      // --------------------------------------------------------

      if (!stopping && pendingReply != null) {
        Future.microtask(processQueue);
      }
    }

    // ----------------------------------------------------------
    // Listen
    // ----------------------------------------------------------

    await for (final msg in receive) {
      if (msg is! Map) {
        continue;
      }

      final command = msg['command'];

      // ========================================================
      // STOP
      // ========================================================

      if (command == PdfWorkerCommand.stopWorker) {
        final reply = msg['reply'];

        if (reply is! SendPort) {
          continue;
        }

        // ------------------------------------------------------
        // Stop receiving new jobs
        // ------------------------------------------------------

        stopping = true;

        // ------------------------------------------------------
        // Cancel pending request
        // ------------------------------------------------------

        final oldPendingReply = pendingReply;

        pendingReply = null;
        pendingPageIndex = null;
        pendingWidth = null;
        pendingHeight = null;
        pendingQuality = null;
        pendingImageType = null;

        if (oldPendingReply != null) {
          try {
            oldPendingReply.send(null);
          } catch (_) {}
        }

        // ------------------------------------------------------
        // IMPORTANT
        //
        // Current native rendering မပြီးသေးရင်
        // pdf_core_destroy() မလုပ်ရ
        // ------------------------------------------------------

        final current = processing;

        if (current != null) {
          try {
            await current;
          } catch (_) {}
        }

        // ------------------------------------------------------
        // အခုမှ core destroy
        // ------------------------------------------------------

        if (pdfCorePtr != nullptr) {
          try {
            pdf_core_destroy(pdfCorePtr);
          } catch (e, st) {
            print('[PdfWorker:destroy] $e');
            print(st);
          }

          pdfCorePtr = nullptr;
        }

        // ------------------------------------------------------
        // Tell main isolate stop completed
        // ------------------------------------------------------

        try {
          reply.send(null);
        } catch (_) {}

        // ------------------------------------------------------
        // Exit worker
        // ------------------------------------------------------

        receive.close();

        break;
      }

      // ========================================================
      // GET IMAGE
      // ========================================================

      if (command == PdfWorkerCommand.getImage) {
        final reply = msg['reply'];

        if (reply is! SendPort) {
          continue;
        }

        // ------------------------------------------------------
        // Already stopping
        // ------------------------------------------------------

        if (stopping) {
          reply.send(null);
          continue;
        }

        // ------------------------------------------------------
        // Validate
        // ------------------------------------------------------

        final pageIndex = msg['pageIndex'];
        final width = msg['width'];
        final height = msg['height'];
        final quality = msg['quality'];
        final imageType = msg['imageType'];

        if (pageIndex is! int ||
            width is! double ||
            height is! double ||
            quality is! int ||
            imageType is! PdfWorkerRequestImageType) {
          reply.send(null);
          continue;
        }

        // ------------------------------------------------------
        // Replace old pending request
        // ------------------------------------------------------

        final oldReply = pendingReply;

        if (oldReply != null && oldReply != reply) {
          try {
            oldReply.send(null);
          } catch (_) {}
        }

        // ------------------------------------------------------
        // Save latest request
        // ------------------------------------------------------

        pendingReply = reply;
        pendingPageIndex = pageIndex;
        pendingWidth = width;
        pendingHeight = height;
        pendingQuality = quality;
        pendingImageType = imageType;

        // ------------------------------------------------------
        // Start process
        // ------------------------------------------------------

        if (processing == null) {
          Future.microtask(processQueue);
        }
      }
    }
  } catch (e, st) {
    print('[_backgroundPdfWorker:error] $e');
    print(st);
  } finally {
    // ----------------------------------------------------------
    // Cleanup pending request
    // ----------------------------------------------------------

    final pending = pendingReply;

    pendingReply = null;

    if (pending != null) {
      try {
        pending.send(null);
      } catch (_) {}
    }

    // ----------------------------------------------------------
    // Wait current render
    // ----------------------------------------------------------

    final current = processing;

    if (current != null) {
      try {
        await current;
      } catch (_) {}
    }

    // ----------------------------------------------------------
    // Destroy PDF Core
    // ----------------------------------------------------------

    if (pdfCorePtr != nullptr) {
      try {
        pdf_core_destroy(pdfCorePtr);
      } catch (e, st) {
        print('[PdfWorker:finalDestroy] $e');
        print(st);
      }

      pdfCorePtr = nullptr;
    }

    receive.close();
  }
}

// ============================================================
// Render Page
// ============================================================

Future<void> _renderPage({
  required Pointer<pdf_core_s> pdfCorePtr,
  required int pageIndex,
  required double width,
  required double height,
  required int quality,
  required PdfWorkerRequestImageType imageType,
  required SendPort reply,
}) async {
  Pointer<pdf_page_s> pagePtr = nullptr;
  Pointer<Int> bufferSizePtr = nullptr;
  Pointer<UnsignedChar> renderBuffer = nullptr;

  try {
    // ----------------------------------------------------------
    // Create page
    // ----------------------------------------------------------

    pagePtr = pdf_page_create(pdfCorePtr, pageIndex);

    if (pagePtr == nullptr) {
      throw StateError(
        'pdf_page_create() returned nullptr '
        '(pageIndex=$pageIndex)',
      );
    }

    // ----------------------------------------------------------
    // Buffer size
    // ----------------------------------------------------------

    bufferSizePtr = calloc<Int>();

    // ----------------------------------------------------------
    // Render
    // ----------------------------------------------------------

    if (imageType == PdfWorkerRequestImageType.png) {
      renderBuffer = pdf_page_renderToPngWH(
        pagePtr,
        bufferSizePtr,
        width.toInt(),
        height.toInt(),
      );
    } else {
      renderBuffer = pdf_page_renderToJpegWH(
        pagePtr,
        bufferSizePtr,
        width.toInt(),
        height.toInt(),
        quality,
      );
    }

    // ----------------------------------------------------------
    // Validate buffer
    // ----------------------------------------------------------

    if (renderBuffer == nullptr) {
      throw StateError(
        'PDF render returned nullptr '
        '(pageIndex=$pageIndex)',
      );
    }

    final size = bufferSizePtr.value;

    if (size <= 0) {
      throw StateError('Invalid render buffer size: $size');
    }

    // ----------------------------------------------------------
    // Native -> Dart
    // ----------------------------------------------------------

    final bytes = renderBuffer.cast<Uint8>().asTypedList(size);

    final trans = TransferableTypedData.fromList([bytes]);

    // ----------------------------------------------------------
    // Reply
    // ----------------------------------------------------------

    reply.send({'width': width, 'height': height, 'trans': trans});
  } catch (e, st) {
    print('[PdfWorker:render] $e');
    print(st);

    try {
      reply.send(null);
    } catch (_) {}
  } finally {
    // ----------------------------------------------------------
    // Free render buffer
    // ----------------------------------------------------------

    if (renderBuffer != nullptr) {
      try {
        pdf_page_free_renderToJpegWH(renderBuffer);
      } catch (e) {
        print('[PdfWorker:freeRenderBuffer] $e');
      }

      renderBuffer = nullptr;
    }

    // ----------------------------------------------------------
    // Destroy page
    // ----------------------------------------------------------

    if (pagePtr != nullptr) {
      try {
        pdf_page_destroy(pagePtr);
      } catch (e) {
        print('[PdfWorker:pageDestroy] $e');
      }

      pagePtr = nullptr;
    }

    // ----------------------------------------------------------
    // Free size
    // ----------------------------------------------------------

    if (bufferSizePtr != nullptr) {
      calloc.free(bufferSizePtr);
      bufferSizePtr = nullptr;
    }
  }
}
