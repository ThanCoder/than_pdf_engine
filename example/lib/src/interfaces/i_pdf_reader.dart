import 'package:than_pdf_engine_example/src/interfaces/i_pdf_platform_controller.dart';
import 'package:than_pdf_engine_example/src/state/reader_state.dart';

abstract class IPdfReader {
  ReaderState get state;

  IPdfPlatformController get pdfPlatformController;
  IPdfContext get pdfContext;
}
