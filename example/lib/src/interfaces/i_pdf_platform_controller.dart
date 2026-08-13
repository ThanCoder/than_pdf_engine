// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:than_pdf_engine/than_pdf_engine.dart';
import 'package:than_pdf_engine_example/src/state/reader_state.dart';
import 'package:than_pdf_engine_example/src/t_pdf_reader_base.dart';



abstract class IScreenComponent {
  Widget build(BuildContext context, BoxConstraints constraints);
}

abstract class IScrollbarView extends IScreenComponent {
  final IPdfContext pdfContext;
  IScrollbarView({required this.pdfContext});
}

abstract class IListenerView {
  final IPdfContext pdfContext;
  IListenerView({required this.pdfContext});

  Widget buildWithChild(
    BuildContext context,
    BoxConstraints constraints,
    Widget child,
  );
}

abstract class IPdfContext {
  ReaderState get state;
  ReaderStateController get stateController;
  TPdfController get tPdfController;
  PdfBackgroundWorker get pdfWorker;
}

abstract class IPdfPlatformController {
  void init();
  void dispose();

  IPdfContext get pdfContext;
  IListenerView get desktopListenerView;
  IListenerView get mobileListenerView;
  IScrollbarView get scrollbarView;
}
