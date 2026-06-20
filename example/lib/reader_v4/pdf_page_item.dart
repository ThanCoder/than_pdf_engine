// ignore_for_file: unused_element, unused_field

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:than_pdf_engine/core/pdf_background_worker.dart';

import 'package:than_pdf_engine_example/reader_v4/core/pdf_reader_state.dart';

class PdfPageItem extends StatefulWidget {
  final PageOffset pageOffset;
  final PdfBackgroundWorker backgroundWorker;
  final bool mobileZooming;
  const PdfPageItem({
    super.key,
    required this.pageOffset,
    required this.backgroundWorker,
    required this.mobileZooming,
  });

  @override
  State<PdfPageItem> createState() => _PdfPageItemState();
}

class _PdfPageItemState extends State<PdfPageItem> {
  Uint8List? lowQualityImage;
  Uint8List? highQualityImage;
  bool isLoading = false;
  bool isHighQuality = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    fetchImage(20);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant PdfPageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mobileZooming) return;
    // double တန်ဖိုးတွေ မသိမသာ ကွာခြားမှုကြောင့် ခဏခဏ အလုပ်မလုပ်အောင် .round() သို့မဟုတ် ခွာပြီး စစ်ပါမယ်
    final bool isPageChanged =
        oldWidget.pageOffset.pageIndex != widget.pageOffset.pageIndex;
    final bool isWidthChanged =
        (oldWidget.pageOffset.width - widget.pageOffset.width).abs() > 0.5;
    final bool isHeightChanged =
        (oldWidget.pageOffset.height - widget.pageOffset.height).abs() > 0.5;

    if (isPageChanged || isWidthChanged || isHeightChanged) {
      _debounceTimer?.cancel();
      setState(() {
        lowQualityImage =
            null; // အသစ်ပြန်ပွင့်ရင် low quality ပါ ရှင်းထုတ်ချင်ရင် ထားပါ (သို့မဟုတ် ချန်ထားနိုင်)
        // highQualityImage = null;
        isHighQuality = false;
        isLoading = false;
      });
      fetchImage(20);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void fetchImage(int quality) async {
    if (isLoading || isHighQuality) return;
    isLoading = true;

    final res = await widget.backgroundWorker.requestPageImageJpg(
      widget.pageOffset.pageIndex,
      width: widget.pageOffset.width,
      height: widget.pageOffset.height,
      quality: quality,
    );
    if (res != null) {
      if (quality > 50) {
        highQualityImage = Uint8List.fromList(res.materialize().asUint8List());
      } else {
        lowQualityImage = Uint8List.fromList(res.materialize().asUint8List());
      }
      isHighQuality = quality > 50;
    }
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
    if (!isHighQuality) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(Duration(milliseconds: 500), () {
        fetchImage(100);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (lowQualityImage == null) {
      return Center(child: CircularProgressIndicator.adaptive());
    }
    return Column(
      children: [
        Expanded(child: _widget),
        IgnorePointer(
          child: Center(child: Text('Page: ${widget.pageOffset.pageIndex}')),
        ),
      ],
    );
    // return _testWidget;
  }

  Widget get _testWidget {
    return SizedBox(
      width: widget.pageOffset.width,
      height: widget.pageOffset.height,
      child: Container(
        color: Colors.red,
        child: Placeholder(
          child: Center(child: Text('Page: ${widget.pageOffset.pageIndex}')),
        ),
      ),
    );
  }

  Widget get _widget {
    final double targetWidth = widget.pageOffset.width;
    final double targetHeight = widget.pageOffset.height;

    return Image.memory(
      // key: ValueKey(
      //   'pdf_page_image-y:${widget.pageOffset.startOffset}-_${widget.pageOffset.pageIndex}',
      // ),
      highQualityImage != null ? highQualityImage! : lowQualityImage!,
      width: targetWidth,
      height: targetHeight,
      gaplessPlayback: true,
      fit: BoxFit.fill,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        return AnimatedOpacity(
          opacity: 1,
          duration: Duration(milliseconds: 300),
          child: child,
        );
      },
    );
  }
}
