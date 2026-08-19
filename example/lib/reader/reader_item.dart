import 'dart:async';
import 'dart:math';
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
  StreamSubscription? _subscription;
  int lastQuality = 0;
  double lastWidth = 0;
  double lastHeight = 0;

  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _subscription = widget.stateController.stream
        .where(
          (e) => e is ZoomChanged || e is MobileScaleChanged || e is ScrollEnd,
        )
        .listen((event) {
          if (lastQuality == 90 &&
              lastWidth == widget.offset.width &&
              lastHeight == widget.offset.height) {
            return;
          }
          print(
            'Dev: need to changed image cache: page: ${widget.offset.pageIndex} - $event',
          );
          _reloadForNewResolution(quality: 90);
        });
    if (lastQuality == 90 &&
        lastWidth == widget.offset.width &&
        lastHeight == widget.offset.height) {
      return;
    }
    _load(quality: 20);
  }

  @override
  void dispose() {
    _subscription?.cancel(); // Memory leak မဖြစ်အောင် Stream ခုတ်ပေးပါ
    super.dispose();
  }

  // Zoom ပြောင်းသွားပါက လက်ရှိ ပုံဟောင်းကို ခေတ္တပြထားပြီး Cache ဖျက်ကာ Resolution အသစ် ဆွဲပေးမည့် Function
  void _reloadForNewResolution({required int quality}) {
    // လက်ရှိ Image ကို Old Image အဖြစ် ခေတ္တ ထိန်းထားပေးပါမည် (Screen ပေါ်တွင် ဝါးမသွားစေရန်)
    if (_newImage != null) {
      _oldImage = _newImage;
      _newImage = null;
    }
    widget.imageCache.remove(widget.offset.pageIndex);
    // widget.imageCache.clear();
    _load(quality: quality);
  }

  Future<void> _load({required int quality}) async {
    final width = widget.offset.width;
    final height = widget.offset.height;
    final pageIndex = widget.offset.pageIndex;

    if (lastQuality == quality && lastWidth == width && lastHeight == height) {
      return;
    }

    final cached = widget.imageCache.get(pageIndex);

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
      quality: quality,
      targetHeight: height.toInt(),
      targetWidth: width.toInt(),
    );

    if (!mounted || requestId != _requestId || res.isErr) {
      return;
    }

    final image = res.unwrap();

    lastQuality = quality;
    lastWidth = width;
    lastHeight = height;

    widget.imageCache.put(pageIndex, image);

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
      final iconSize = min(widget.offset.width, widget.offset.height) * 0.4;
      return Icon(Icons.image_not_supported_rounded, size: iconSize);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (oldImage != null)
          Image.memory(oldImage, fit: BoxFit.fill, gaplessPlayback: true),

        if (newImage != null)
          Image.memory(newImage, fit: BoxFit.fill, gaplessPlayback: true),
      ],
    );
  }
}
