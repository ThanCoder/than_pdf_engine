// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:than_pdf_engine/core/high_level_api/reader/pdf_reader_worker.dart';
import 'package:than_pdf_engine_example/reader/controllers/page_offset.dart';
import 'package:than_pdf_engine_example/reader/controllers/reader_state_controller.dart';
import 'package:than_pdf_engine_example/reader/utils/page_image_cache.dart';

class ReaderItem extends StatefulWidget {
  const ReaderItem({
    super.key,
    required this.offset,
    required this.stateController,
    required this.worker,
    required this.imageCache,
  });
  final PageOffset offset;
  final ReaderStateController stateController;
  final PdfReaderWorker worker;
  final PageImageCache imageCache;

  @override
  State<ReaderItem> createState() => _ReaderItemState();
}

class _ReaderItemState extends State<ReaderItem> {
  @override
  void initState() {
    super.initState();

    final data = widget.imageCache.get(
      widget.offset.pageIndex,
      width: widget.offset.width,
      height: widget.offset.height,
    );

    if (data == null) {
      init();
    }
  }

  @override
  void didUpdateWidget(covariant ReaderItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.offset.width != widget.offset.width ||
        oldWidget.offset.height != widget.offset.height) {
      init();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void init() async {
    final res = await widget.worker.getImage(
      widget.offset.pageIndex,
      quality: 90,
      targetHeight: widget.offset.height.toInt(),
      targetWidth: widget.offset.width.toInt(),
    );
    if (res.isErr) {
      if (!mounted) return;
      setState(() {});
      return;
    }
    widget.imageCache.put(
      widget.offset.pageIndex,
      res.unwrap(),
      width: widget.offset.width,
      height: widget.offset.height,
    );
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .center,
      children: [
        Text('Page: ${widget.offset.pageIndex}'),
        Expanded(child: body()),
      ],
    );
  }

  Uint8List? oldCache;

  Widget body() {
    final data = widget.imageCache.get(
      widget.offset.pageIndex,
      width: widget.offset.width,
      height: widget.offset.height,
    );
    if (data != null) {
      oldCache = data;
    }

    return AnimatedOpacity(
      opacity: oldCache == null ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: oldCache == null
          ? const SizedBox.expand()
          : Image.memory(
              oldCache!,
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.image_not_supported_outlined);
              },
            ),
    );
  }
}
