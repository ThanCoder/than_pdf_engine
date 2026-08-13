import 'package:flutter/material.dart';
import 'package:than_pdf_engine_example/src/interfaces/i_pdf_platform_controller.dart';
import 'package:than_pdf_engine_example/src/logic_controllers/desktop_listener_view.dart';
import 'package:than_pdf_engine_example/src/logic_controllers/mobile_listener_view.dart';
import 'package:than_pdf_engine_example/src/t_pdf_reader_base.dart';

class PdfPlatformController extends IPdfPlatformController {
  final IPdfContext context;
  PdfPlatformController({required this.context});

  // 💡 FocusNode ကို ဒီမှာ တစ်ကြိမ်တည်း အသေဆောက်ထားမယ်
  final FocusNode pageFocusNode = FocusNode();

  @override
  void init() {}

  @override
  void dispose() {
    context.stateController.dispose();
    pageFocusNode.dispose();
  }

  @override
  IPdfContext get pdfContext => context;

  @override
  late final MobileListenerView mobileListenerView = MobileListenerView(
    pdfContext: context,
  );

  @override
  late final IScrollbarView scrollbarView = ScrollbarView(
    pdfContext: pdfContext,
  );

  @override
  late final IListenerView desktopListenerView = DesktopListenerView(
    pdfContext: context,
    pageFocusNode: pageFocusNode,
  );
}
