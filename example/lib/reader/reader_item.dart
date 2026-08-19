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
  Uint8List? _oldImage;
  Uint8List? _newImage;

  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ReaderItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.offset.width != widget.offset.width ||
        oldWidget.offset.height != widget.offset.height) {
      _load();
    }
  }

  Future<void> _load() async {
    final width = widget.offset.width;
    final height = widget.offset.height;
    final pageIndex = widget.offset.pageIndex;

    final cached = widget.imageCache.get(
      pageIndex,
      width: width,
      height: height,
    );

    if (cached != null) {
      if (!mounted) return;

      setState(() {
        _oldImage = cached;
        _newImage = null;
      });

      return;
    }

    final requestId = ++_requestId;

    final res = await widget.worker.getImage(
      pageIndex,
      quality: 90,
      targetHeight: height.toInt(),
      targetWidth: width.toInt(),
    );

    if (!mounted || requestId != _requestId || res.isErr) {
      return;
    }

    final image = res.unwrap();

    widget.imageCache.put(pageIndex, image, width: width, height: height);

    if (!mounted || requestId != _requestId) {
      return;
    }

    setState(() {
      _newImage = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Page: ${widget.offset.pageIndex}'),
        Expanded(child: _image()),
      ],
    );
  }

  Widget _image() {
    final oldImage = _oldImage;
    final newImage = _newImage;

    if (oldImage == null && newImage == null) {
      return const Icon(Icons.image_not_supported_rounded, size: 300);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (oldImage != null)
          Image.memory(oldImage, fit: BoxFit.fill, gaplessPlayback: true),

        if (newImage != null)
          AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 150),
            child: Image.memory(
              newImage,
              fit: BoxFit.fill,
              gaplessPlayback: true,
            ),
          ),
      ],
    );
  }
}
