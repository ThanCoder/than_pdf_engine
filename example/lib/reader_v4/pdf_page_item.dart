// ignore_for_file: unused_element, unused_field

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:than_pdf_engine/core/pdf_background_worker.dart';
import 'package:than_pdf_engine_example/reader_v4/pdf_reader_base.dart';

class PdfPageItem extends StatefulWidget {
  final PageOffset pageOffset;
  final PdfBackgroundWorker backgroundWorker;
  const PdfPageItem({
    super.key,
    required this.pageOffset,
    required this.backgroundWorker,
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
    // 💡 ပြင်ဆင်ချက်: Index၊ Width သို့မဟုတ် Height ထဲက တစ်ခုခု "မတူတော့ရင်" (ပြောင်းလဲသွားရင်) ပုံအသစ်ဆွဲမယ်
    if (oldWidget.pageOffset.pageIndex != widget.pageOffset.pageIndex ||
        oldWidget.pageOffset.width != widget.pageOffset.width ||
        oldWidget.pageOffset.height != widget.pageOffset.height) {
      highQualityImage = null;
      isHighQuality = false;
      fetchImage(20);
      print(
        'did update: zoom သို့မဟုတ် စာမျက်နှာ ပြောင်းသွားသဖြင့် ပုံအသစ်ပြန်ယူသည်',
      );
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
        fetchImage(90);
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

    if (highQualityImage != null) {
      return Image.memory(
        width: targetWidth,
        height: targetHeight,
        gaplessPlayback: true,
        fit: BoxFit.fill,

        highQualityImage!,
      );
    }
    return Image.memory(
      lowQualityImage!,
      width: targetWidth,
      height: targetHeight,
      gaplessPlayback: true,
      fit: BoxFit.fill,
    );
  }
}
