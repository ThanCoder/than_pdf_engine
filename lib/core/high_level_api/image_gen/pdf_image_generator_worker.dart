part of 'pdf_image_generator.dart';

enum PdfImageGeneratorWorkerCommand {
  generate,
  close;

  static PdfImageGeneratorWorkerCommand fromValue(String val) {
    return values.firstWhere((e) => e.name == val, orElse: () => close);
  }
}

enum PdfImageGeneratorWorkerResult {
  success,
  error,
  unknown;

  static PdfImageGeneratorWorkerResult fromValue(String val) {
    return values.firstWhere((e) => e.name == val, orElse: () => unknown);
  }
}

Future<void> _pdfImageGeneratorWorker(SendPort port) async {
  final rec = ReceivePort();
  port.send(rec.sendPort);

  bindings.FPDF_InitLibrary();

  rec.listen((message) {
    if (message is! Map) return;

    final reply = message['reply'] as SendPort;
    final command = message['command'] as PdfImageGeneratorWorkerCommand;

    //close isolate
    if (command == .close) {
      bindings.FPDF_DestroyLibrary();
      rec.close();
      reply.send(true);
      return;
    }

    final path = message['path'] as String;
    final outPath = message['outPath'] as String;
    final pageIndex = message['pageIndex'] as int;
    final quality = message['quality'] as int;
    final targetWidth = message['targetWidth'] as int;
    final targetHeight = message['targetHeight'] as int;
    final renderImageType = message['renderImage'] as PageRenderImageType;

    if (command == .generate) {
      final doc = PdfDocumentFile();
      final docRes = doc.open(path);
      if (docRes.isErr) {
        reply.send({
          'result': PdfImageGeneratorWorkerResult.error,
          'message': docRes.unwrapError(),
        });
        return;
      }

      final page = PdfPage(doc);
      final pageRes = page.loadPage(pageIndex);
      if (pageRes.isErr) {
        doc.close();

        reply.send({
          'result': PdfImageGeneratorWorkerResult.error,
          'message': pageRes.unwrapError(),
        });

        return;
      }

      final res = page.saveImageFile(
        outPath,
        quality: quality,
        renderImageType: renderImageType,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      if (res.isErr) {
        reply.send({
          'result': PdfImageGeneratorWorkerResult.error,
          'message': res.unwrapError(),
        });
        //free memory
        page.close();
        doc.close();
        return;
      }
      //free memory
      page.close();
      doc.close();
      // success
      reply.send({
        'result': PdfImageGeneratorWorkerResult.success,
        'message': 'Generated',
      });
    }
  });
}
