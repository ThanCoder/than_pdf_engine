import 'dart:async';

import 'package:flutter/material.dart';
import 'package:than_pdf_engine_example/src/default_widgets/scrollbar_widgets.dart';
import 'package:than_pdf_engine_example/src/events/pdf_events.dart';
import 'package:than_pdf_engine_example/src/events/user_events.dart';
import 'package:than_pdf_engine_example/src/interfaces/i_pdf_platform_controller.dart';
import 'package:than_pdf_engine_example/src/logic_controllers/mobile_listener_view.dart';
import 'package:than_pdf_engine_example/src/logic_controllers/pdf_context.dart';
import 'package:than_pdf_engine_example/src/logic_controllers/pdf_platform_controller.dart';
import 'package:than_pdf_engine_example/src/reader/page_list_item.dart';
import 'package:than_pdf_engine_example/src/reader/reader_layout_engine.dart';
import 'package:than_pdf_engine_example/src/state/reader_state.dart';
import 'package:than_pdf_engine_example/src/events/state_events.dart';
import 'package:than_pdf_engine/than_pdf_engine.dart';

part 't_pdf_controller.dart';
part 'reader/t_reader.dart';
part 'state/reader_state_controller.dart';
part 'logic_mixins/scrollbar_handler.dart';
part 'logic_controllers/scrollbar_view.dart';

class TPdfReader extends StatefulWidget {
  final String path;
  final String? password;
  final TPdfController controller;
  const TPdfReader({
    super.key,
    required this.path,
    this.password,
    required this.controller,
  });

  @override
  State<TPdfReader> createState() => _TPdfReaderState();
}

class _TPdfReaderState extends State<TPdfReader> {
  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void dispose() {
    pdfWorker.dispose();
    super.dispose();
  }

  final pdfWorker = PdfBackgroundWorker.getInstance;
  List<PageSize> pageSizes = [];
  bool isLoading = false;
  String? error;

  void init() async {
    try {
      widget.controller._pdfLoadedStopWatch.start();
      setState(() {
        isLoading = true;
      });
      final (list, error) = await PdfCore.getAllPageSizedList(widget.path);
      pageSizes = list;
      this.error = error;
      if (error != null) {
        // await pdfWorker.requestPageImageJpg(pageIndex, width: width, height: height)
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        return;
      }
      await pdfWorker.run(widget.path);
      // await pdfWorker.requestPageImageJpg(pageIndex, width: width, height: height)
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('[TPdfReader:init]: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      if (widget.controller.progressWidget != null) {
        return Center(child: widget.controller.progressWidget!(context));
      }
      return Center(child: CircularProgressIndicator.adaptive());
    }
    if (error != null) {
      return Center(
        child: Text(error!, style: TextStyle(fontSize: 18, color: Colors.red)),
      );
    }
    return TReader(
      pageSizes: pageSizes,
      pdfWorker: pdfWorker,
      controller: widget.controller,
    );
  }
}
