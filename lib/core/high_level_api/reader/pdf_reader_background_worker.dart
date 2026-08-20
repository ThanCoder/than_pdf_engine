part of 'pdf_reader_worker.dart';

enum PdfReaderWorkerCommand { genImage, getPageSize, close }

enum PdfReaderWorkerResult { success, error, unknown }

class PdfReaderWorkerOpenErrorResult {
  final PdfiumStatus? status;
  final String message;

  const PdfReaderWorkerOpenErrorResult({this.status, required this.message});
}

typedef PageSizeRaw = (int page, double width, double height);

Future<void> _backgroundWorker((SendPort, String) args) async {
  final rec = ReceivePort();
  final (port, path) = args;

  bindings.FPDF_InitLibrary();

  final doc = PdfDocumentFile();
  final docRes = doc.open(path);
  if (docRes.isErr) {
    port.send({
      'result': PdfReaderWorkerResult.error,
      'status': docRes.unwrapError(),
      'message': docRes.unwrapError().toString(),
    });
    rec.close();
    bindings.FPDF_DestroyLibrary();
    return;
  }

  port.send({
    'result': PdfReaderWorkerResult.success,
    'workerPort': rec.sendPort,
  });

  rec.listen((message) {
    if (message is! Map) return;
    final reply = message['reply'] as SendPort;
    final command = message['command'] as PdfReaderWorkerCommand;

    if (command == .close) {
      doc.close();
      // bindings.FPDF_DestroyLibrary();
      reply.send(true);
      rec.close();
      return;
    }
    if (command == .getPageSize) {
      final res = doc.allPages;
      if (res.isErr) {
        reply.send({
          'result': PdfReaderWorkerResult.error,
          'message': res.unwrapError(),
        });
        return;
      }
      final list = res
          .unwrap()
          .map((e) => [e.page, e.width, e.height])
          .toList();
      // success
      reply.send({'result': PdfReaderWorkerResult.success, 'list': list});
    }

    if (command == .genImage) {
      final pageIndex = message['pageIndex'] as int;
      final quality = message['quality'] as int;
      final targetWidth = message['targetWidth'] as int;
      final targetHeight = message['targetHeight'] as int;
      final renderImageType = message['renderImageType'] as PageRenderImageType;

      final page = PdfPage(doc);
      final pageRes = page.loadPage(pageIndex);
      if (pageRes.isErr) {
        reply.send({
          'result': PdfReaderWorkerResult.error,
          'message': pageRes.unwrapError(),
        });
        return;
      }
      final imageRes = page.renderPageImage(
        quality: quality,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        renderImageType: renderImageType,
      );
      // close page
      page.close();

      if (imageRes.isErr) {
        reply.send({
          'result': PdfReaderWorkerResult.error,
          'message': imageRes.unwrapError(),
        });
        return;
      }

      // success
      reply.send({
        'result': PdfReaderWorkerResult.success,
        'data': TransferableTypedData.fromList([imageRes.unwrap()]),
      });
    }
  });
}
