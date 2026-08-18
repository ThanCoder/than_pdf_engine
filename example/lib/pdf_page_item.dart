import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:than_pdf_engine/core/high_level_api/reader/pdf_reader_worker.dart';
import 'package:than_pdf_engine/core/models/page_size.dart';
import 'package:than_pdf_engine_example/image_queue.dart';

class PdfPageItem extends StatefulWidget {
  const PdfPageItem({
    super.key,
    required this.pageZ,
    required this.worker,
    required this.imageQueue,
  });

  final PageSize pageZ;
  final PdfReaderWorker worker;
  final PdfImageQueue imageQueue;

  @override
  State<PdfPageItem> createState() => _PdfPageItemState();
}

class _PdfPageItemState extends State<PdfPageItem> {
  bool isWorking = false;
  @override
  void initState() {
    super.initState();

    // print('INIT PAGE ${widget.pageZ.page}');

    // widget.imageQueue.request(widget.pageZ.page);
    // widget.imageQueue.onImage = (page, quality, data) {
    //   print('page: $quality - data: ${data.length}');

    //   if (!mounted) return;
    //   setState(() {
    //     this.data = data;
    //   });
    // };
  }

  @override
  void dispose() {
    data = null;
    // print('DISPOSE PAGE ${widget.pageZ.page}');

    widget.imageQueue.cancel(widget.pageZ.page);

    super.dispose();
  }

  Uint8List? data;
  bool isLoading = false;
  String? error;

  void init() async {
    if (data != null) return;
    setState(() {
      isLoading = true;
    });
    final res = await widget.worker.getImage(
      widget.pageZ.page,
      quality: 10,
      targetWidth: widget.pageZ.width.toInt(),
      targetHeight: widget.pageZ.height.toInt(),
    );
    if (res.isErr) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      return;
    }
    data = res.unwrap();
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.pageZ.width,
      height: widget.pageZ.height,
      decoration: BoxDecoration(border: .all()),
      child: body(),
    );
  }

  Widget body() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator.adaptive());
    }
    if (error != null) {
      return Center(
        child: Text(error!, style: TextStyle(color: Colors.red)),
      );
    }
    if (data == null) {
      return Center(
        child: Text(
          'Page: ${widget.pageZ.page}\nImage is Null',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return Image.memory(
      data!,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.image_not_supported_outlined),
    );
  }
}
