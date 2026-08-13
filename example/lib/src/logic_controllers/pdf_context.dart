// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:than_pdf_engine/core/pdf_background_worker.dart';

import 'package:than_pdf_engine_example/src/interfaces/i_pdf_platform_controller.dart';
import 'package:than_pdf_engine_example/src/state/reader_state.dart';
import 'package:than_pdf_engine_example/src/t_pdf_reader_base.dart';

class PdfContext extends IPdfContext {
  PdfContext({
    required this.pdfWorker,
    required this.stateController,
    required this.tPdfController,
  });

  @override
  late final PdfBackgroundWorker pdfWorker;

  @override
  ReaderState get state => stateController.state;

  @override
  late final ReaderStateController stateController;

  @override
  late final TPdfController tPdfController;
}
