import 'package:flutter/material.dart';
import 'package:than_pdf_engine/than_pdf_engine.dart';
import 'package:than_pdf_engine_example/reader_v4/pdf_reader_base.dart';

class PdfReader extends StatefulWidget {
  final String path;
  const PdfReader({super.key, required this.path});

  @override
  State<PdfReader> createState() => _PdfReaderState();
}

class _PdfReaderState extends State<PdfReader> {
  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void dispose() {
    PdfBackgroundWorker.getInstance.dispose();
    super.dispose();
  }

  List<PageSize> pageSizeList = [];
  bool isLoading = false;
  final backgroundWorker = PdfBackgroundWorker.getInstance;
  void init() async {
    try {
      setState(() {
        isLoading = true;
      });
      pageSizeList = await PdfCore.getAllPageSizedList(widget.path);
      await backgroundWorker.run(widget.path);
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator.adaptive());
    }
    return PdfReaderBase(
      pageSizeList: pageSizeList,
      backgroundWorker: backgroundWorker,
    );
  }
}
