import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:than_pdf_engine_example/src/reader/page_offset.dart';
import 'package:than_pdf_engine/core/pdf_background_worker.dart';
import 'package:than_pdf_engine_example/src/t_pdf_reader_base.dart';

class PageListItem extends StatefulWidget {
  final PageOffset page;
  final PdfBackgroundWorker pdfWorker;
  final TPdfController controller;
  final ReaderStateController readerStateController;

  const PageListItem({
    super.key,
    required this.page,
    required this.pdfWorker,
    required this.controller,
    required this.readerStateController,
  });

  @override
  State<PageListItem> createState() => _PageListItemState();
}

class _PageListItemState extends State<PageListItem> {
  Uint8List? lowImage;
  Uint8List? highImage;

  // 💡 Loading state များကို သီးခြားခွဲထုတ်လိုက်ပါ
  bool isLoadingLow = false;
  bool isLoadingHigh = false;

  Timer? _requestHighImageTimer;
  final imageDataChangeNotifier = ValueNotifier<int>(1);

  StreamSubscription? _stateSubscription;
  bool _isReaderScrolling = false;

  @override
  void initState() {
    _isReaderScrolling = widget.readerStateController.state.isScrolling;

    super.initState();

    _stateSubscription = widget.readerStateController.stateStream
        .map((s) => s.isScrolling)
        .distinct()
        .listen((isScrolling) {
          _isReaderScrolling = isScrolling;

          if (!isScrolling && highImage == null) {
            _requestHighImageTimer?.cancel();
            _requestHighImageTimer = Timer(
              const Duration(milliseconds: 200),
              () {
                requestHighImage();
              },
            );
          } else if (isScrolling) {
            _requestHighImageTimer?.cancel();
          }
        });

    requestLowImage();
  }

  @override
  void didUpdateWidget(covariant PageListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.page.width != oldWidget.page.width ||
        widget.page.height != oldWidget.page.height) {
      highImage = null;
      _requestHighImageTimer?.cancel();
      requestHighImage();
    }
  }

  @override
  void dispose() {
    // 💡 Memory leak မဖြစ်အောင် ValueNotifier ကိုပါ dispose လုပ်ပေးရပါမယ်
    imageDataChangeNotifier.dispose();
    _requestHighImageTimer?.cancel();
    _stateSubscription?.cancel();
    lowImage = null;
    highImage = null;
    super.dispose();
  }

  void requestLowImage() async {
    try {
      if (isLoadingLow || lowImage != null) return;
      if (mounted) {
        setState(() {
          isLoadingLow = true;
        });
      }

      final res = await widget.pdfWorker.requestPageImage(
        widget.page.pageIndex,
        width: widget.page.width,
        height: widget.page.height,
        quality: 20,
        type: .jpg, // 💡 `.jpg` မှ `ImageType.jpg` သို့ ပြင်ဆင်ထားသည်
      );

      if (!mounted) return;

      if (res != null) {
        lowImage = Uint8List.fromList(res.trans.materialize().asUint8List());
      }

      setState(() {
        isLoadingLow = false;
      });
      // 💡 Low Image ရသွားပြီဆိုတာနဲ့ Scroll မလုပ်နေဘူးဆိုရင် High Image ကို တောင်းခိုင်းမယ်
      if (highImage == null && !_isReaderScrolling) {
        _requestHighImageTimer?.cancel();
        _requestHighImageTimer = Timer(const Duration(milliseconds: 200), () {
          requestHighImage();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingLow = false;
      });
      debugPrint('[requestLowImage]: $e');
    }
  }

  void requestHighImage() async {
    try {
      if (_isReaderScrolling || isLoadingHigh || highImage != null) return;
      isLoadingHigh = true;

      final res = await widget.pdfWorker.requestPageImage(
        widget.page.pageIndex,
        width: widget.page.width,
        height: widget.page.height,
        quality: 100,
        type: widget.controller.requestRenderHighQualityImageType,
      );

      if (!mounted) return; // 💡 Component unmount ဖြစ်သွားပါက ဆက်မလုပ်စေရန်

      if (res != null) {
        highImage = Uint8List.fromList(res.trans.materialize().asUint8List());
      }

      isLoadingHigh = false;
      imageDataChangeNotifier.value += 1;
    } catch (e) {
      if (!mounted) return;
      isLoadingHigh = false;
      debugPrint('[requestHighImage]: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.page.width,
      height: widget.page.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: ValueListenableBuilder<int>(
              valueListenable: imageDataChangeNotifier,
              builder: (context, value, child) {
                return imageWidget;
              },
            ),
          ),

          // footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: footerWidget,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget get footerWidget {
    if (widget.controller.pageFooterWidget != null) {
      return widget.controller.pageFooterWidget!(widget.page.pageIndex + 1);
    }
    return Text(
      'Page: ${widget.page.pageIndex + 1}',
      style: const TextStyle(color: Colors.black),
    );
  }

  Widget get imageWidget {
    if (highImage != null) {
      return image(highImage!);
    }
    if (lowImage != null) {
      return image(lowImage!);
    }

    return const Center(child: CircularProgressIndicator.adaptive());
  }

  Widget image(Uint8List data) {
    return Image.memory(
      data,
      fit: BoxFit.fitWidth,
      gaplessPlayback: true,
      width: widget.page.width,
      height: widget.page.height,
    );
  }
}
