// ignore_for_file: avoid_print, public_member_api_docs, sort_constructors_first
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:than_pdf_engine/than_pdf_engine.dart';
import 'package:than_pdf_engine_example/reader_v4/pdf_page_item.dart';

class PageOffset {
  final double startOffset;
  final double endOffset;
  final int pageIndex;
  final double width;
  final double height;
  PageOffset({
    required this.startOffset,
    required this.endOffset,
    required this.pageIndex,
    required this.width,
    required this.height,
  });
}

class PageScale {
  final double offsetX;
  final double offsetY;
  final int pageIndex;
  const PageScale({this.offsetX = 0, this.offsetY = 0, this.pageIndex = 0});

  PageScale copyWith({
    double? offsetX,
    double? offsetY,
    double? zoomFactor,
    int? pageIndex,
  }) {
    return PageScale(
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      pageIndex: pageIndex ?? this.pageIndex,
    );
  }
}

class PdfReaderBase extends StatefulWidget {
  final List<PageSize> pageSizeList;
  final PdfBackgroundWorker backgroundWorker;
  const PdfReaderBase({
    super.key,
    required this.pageSizeList,
    required this.backgroundWorker,
  });

  @override
  State<PdfReaderBase> createState() => _PdfReaderBaseState();
}

class _PdfReaderBaseState extends State<PdfReaderBase> {
  final transformationController = TransformationController();
  @override
  void initState() {
    super.initState();
    transformationController.addListener(() {
      print('scroll');
      setState(() {
        // Matrix4 ရဲ့ translation ကနေ လက်ရှိ y-offset ကို ယူတာပါ (InteractiveViewer မှာက ပြောင်းပြန်မို့လို့ - ခံရပါတယ်)
        currenScrollOffset = -transformationController.value.row0.a;
      });
    });
  }

  @override
  void dispose() {
    transformationController.dispose();
    super.dispose();
  }

  List<PageOffset> pageOffsets = [];
  bool isLoading = false;
  double currenScrollOffset = 0;
  double totalContentHeight = 0;
  BoxConstraints? _lastConstraints;
  PageScale currentPageScale = const PageScale();
  double zoomFactor = 0.6;
  double zoomMinScale = 0.2;
  double zoomMaxScale = 5;
  double _lastZoomFactor = 1.0;

  void calculateLayout(BoxConstraints constraints) {
    if (widget.pageSizeList.isEmpty) return;

    // Constraints ရော Zoom ရော မပြောင်းလဲရင် ကျော်သွားမယ်
    // (ဒီနေရာမှာ Layout လှည့်ရင် constraints.maxWidth ပြောင်းမှာဖြစ်လို့ အောက်က save/restore ထဲ ဝင်သွားပါလိမ့်မယ်)
    if (_lastConstraints?.maxWidth == constraints.maxWidth &&
        _lastConstraints?.maxHeight == constraints.maxHeight &&
        _lastZoomFactor == zoomFactor &&
        pageOffsets.isNotEmpty) {
      return;
    }
    // if (_isScaling) return;

    // Layout ပြောင်းလဲချိန်မှာ Scroll Position မလွဲအောင် သိမ်းဆည်းမယ်
    saveCurrentState();

    _lastConstraints = constraints;
    _lastZoomFactor = zoomFactor;
    pageOffsets.clear();

    totalContentHeight = 0;

    for (var i = 0; i < widget.pageSizeList.length; i++) {
      final page = widget.pageSizeList[i];

      // 💡 အဓိက ပြင်ဆင်ချက်: Screen Width နဲ့ ဘာမှ မဆိုင်တော့ဘဲ
      // မူရင်း PDF Size ကို Zoom Factor နဲ့ပဲ တိုက်ရိုက်မြှောက်ပါတော့တယ်
      double renderWidth = page.width * zoomFactor;
      double renderHeight = page.height * zoomFactor;

      pageOffsets.add(
        PageOffset(
          startOffset: totalContentHeight,
          endOffset: totalContentHeight + renderHeight,
          pageIndex: i,
          width: renderWidth,
          height: renderHeight,
        ),
      );

      totalContentHeight += renderHeight;
    }

    // နေရာဟောင်းကို အချိုးကျ ပြန်ရှာမယ်
    restoreCurrentState();
  }

  List<PageOffset> getVisiablePages(double viewportHeight) {
    List<PageOffset> list = [];

    if (pageOffsets.isEmpty) return list;
    // ၁။ မျက်နှာပြင်ပေါ်မှာ လက်ရှိ တကယ်မြင်နေရတဲ့ ပထမဆုံး စာမျက်နှာ Index (Current Page) ကို ရှာမယ်
    final currentIndex = _firstVisiableIndex(currenScrollOffset);

    // ရှေ့/နောက် ပြသချင်တဲ့ စာမျက်နှာ အရေအတွက် (သင်လိုချင်တာက ၃ ခုစီ)
    // 💡 လျှို့ဝှက်ချက်: Zoom သေးရင် သေးသလောက် စာမျက်နှာတွေ ပိုယူပေးဖို့ တွက်ချက်မယ်
    // ဥပမာ - zoomFactor က 1.0 ဆိုရင် cache က 3 စောင်၊ zoomFactor က 0.3 ဆိုရင် cache က 10 စောင် ဖြစ်သွားပါမယ်
    int cacheCount = (3 / zoomFactor).ceil().clamp(3, 15);

    // ၂။ စတင်မည့် Index ကို တွက်ချက်မယ် (Current ရဲ့ အပေါ် ၃ ခု၊ အနည်းဆုံး 0)
    final startIndex = (currentIndex - cacheCount).clamp(
      0,
      pageOffsets.length - 1,
    );

    // ၃။ အဆုံးသတ်မည့် Index ကို တွက်ချက်မယ် (Current ရဲ့ အောက် ၃ ခု၊ အများဆုံး စာမျက်နှာ စုစုပေါင်းအရေအတွက်)
    final endIndex = (currentIndex + cacheCount).clamp(
      0,
      pageOffsets.length - 1,
    );

    // ၄။ သတ်မှတ်ထားတဲ့ ပတ်ပတ်လည် Range (startIndex မှ endIndex အထိ) ကိုပဲ Loop ပတ်ပြီး ထည့်ပေးမယ်
    for (var i = startIndex; i <= endIndex; i++) {
      list.add(pageOffsets[i]);
    }

    return list;
  }

  int _firstVisiableIndex(double scrollOffset) {
    int low = 0;
    int height = pageOffsets.length - 1;
    while (low <= height) {
      final mid = low + (height - low) ~/ 2;
      final page = pageOffsets[mid];
      if (page.endOffset < scrollOffset) {
        low = mid + 1;
      } else if (page.startOffset > scrollOffset) {
        height = mid - 1;
      } else {
        return mid;
      }
    }
    return low.clamp(0, pageOffsets.length - 1);
  }

  void saveCurrentState() {
    if (pageOffsets.isEmpty) return;
    final currentPage = pageOffsets[_firstVisiableIndex(currenScrollOffset)];
    final internalOffsetY = currenScrollOffset - currentPage.startOffset;
    final pageOffsetYRatio = internalOffsetY / currentPage.height;
    currentPageScale = currentPageScale.copyWith(
      offsetY: pageOffsetYRatio,
      pageIndex: currentPage.pageIndex,
    );
  }

  void restoreCurrentState() {
    final targetIndex = currentPageScale.pageIndex;

    if (pageOffsets.isEmpty || targetIndex >= pageOffsets.length) return;

    final newPage = pageOffsets[targetIndex];

    // Ratio အတိုင်း Pixel ပြန်ရှာမယ်
    double ratioY = currentPageScale.offsetY.isFinite
        ? currentPageScale.offsetY
        : 0.0;
    double actualPixelOffsetY = newPage.height * ratioY;

    double targetScrollOffset = newPage.startOffset + actualPixelOffsetY;

    if (targetScrollOffset.isFinite) {
      // 💡 အဓိက လျှို့ဝှက်ချက် - မျက်နှာပြင်အမြင့်သစ်အရ အများဆုံး Scroll လို့ရမယ့် Limit အသစ်ကို ပြန်တွက်ရပါမယ်
      // _lastConstraints က LayoutBuilder ကနေ ရလာတဲ့ လက်ရှိ screen size ဖြစ်ပါတယ်
      final maxScrollExtent =
          (totalContentHeight - (_lastConstraints?.maxHeight ?? 0.0)).clamp(
            0.0,
            double.infinity,
          );

      // ရလာတဲ့ offset ကို bounds ကျော်မသွားအောင် ညှိလိုက်ရင် လုံးဝ မပြောင်းလဲတော့ပါဘူး
      currenScrollOffset = targetScrollOffset.clamp(0.0, maxScrollExtent);
    } else {
      currenScrollOffset = 0.0;
    }

    currentPageScale = PageScale(
      offsetX: 0,
      offsetY: ratioY,
      pageIndex: targetIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        calculateLayout(constraints);
        return Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              setState(() {
                currenScrollOffset += event.scrollDelta.dy;
                // စာမျက်နှာအောက်ခြေထက် ကျော်မသွားအောင် တွက်ချက်ခြင်း
                // (Max Scroll Limit ဟာ Total Height ထဲကနေ မျက်နှာပြင်အမြင့်ကို နှုတ်ထားတာ ဖြစ်ရပါမယ်)
                final maxScrollExtent =
                    (totalContentHeight - constraints.maxHeight).clamp(
                      0.0,
                      double.infinity,
                    );
                currenScrollOffset = currenScrollOffset.clamp(
                  0.0,
                  maxScrollExtent,
                );
                print('scroll-y: $currenScrollOffset');
              });
            }
          },
          child: mobileScrollListener(constraints),
        );
      },
    );
  }

  Widget mobileScrollListener(BoxConstraints constraints) {
    return Stack(
      children: [
        ...buildStackPositionedPageList(constraints),
        scrollStackPositionedWidget(constraints),
        Positioned(left: 0, child: _testRow),
      ],
    );
  }

  Widget get _testRow {
    return Container(
      color: Colors.black,
      child: Row(
        children: [
          IconButton(
            color: Colors.tealAccent,
            onPressed: zoomDown,
            icon: Icon(Icons.zoom_out),
          ),
          IconButton(
            color: Colors.tealAccent,
            onPressed: zoomUp,
            icon: Icon(Icons.zoom_in),
          ),
        ],
      ),
    );
  }

  Widget scrollStackPositionedWidget(BoxConstraints constraints) {
    double thumbWidth = 50;
    double thumbHeight = 50;
    final viewportHeight = constraints.maxHeight;
    final maxScrollExtent = (totalContentHeight - viewportHeight).clamp(
      0.0,
      double.infinity,
    );

    double scrollRatio = 0;
    if (maxScrollExtent > 0) {
      scrollRatio = currenScrollOffset / maxScrollExtent;
    }
    final thumbTopOffset = scrollRatio * (viewportHeight - thumbHeight);

    return Positioned(
      top: thumbTopOffset.isFinite ? thumbTopOffset : 0.0,
      right: 10,
      width: thumbWidth,
      height: thumbHeight,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (maxScrollExtent <= 0) return;
          double scrollDeltaY = details.delta.dy * 2;
          double newThumbTop = thumbTopOffset + scrollDeltaY;
          newThumbTop = newThumbTop.clamp(0.0, viewportHeight - thumbHeight);
          final topRatio = newThumbTop / (viewportHeight - thumbHeight);
          setState(() {
            currenScrollOffset = topRatio * maxScrollExtent;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
      ),
    );
  }

  List<Widget> buildStackPositionedPageList(BoxConstraints constraints) {
    final list = <Widget>[];
    final showPageIndex = <int>[];
    for (var page in getVisiablePages(constraints.maxHeight)) {
      // print('page: ${page.pageIndex}');
      showPageIndex.add(page.pageIndex);

      final leftOffset = (constraints.maxWidth - page.width) / 2;
      final topOffset = page.startOffset - currenScrollOffset;
      list.add(
        Positioned(
          left: leftOffset,
          top: topOffset,
          height: page.height,
          width: page.width,
          child: PdfPageItem(
            pageOffset: page,
            backgroundWorker: widget.backgroundWorker,
          ),
        ),
      );
    }
    print('show Page index: $showPageIndex');
    // print('showPage: ${list.length}');
    return list;
  }

  void zoomUp() {
    zoomFactor = (zoomFactor + 0.1).clamp(zoomMinScale, zoomMaxScale);
    setState(() {});
  }

  void zoomDown() {
    zoomFactor = (zoomFactor - 0.1).clamp(zoomMinScale, zoomMaxScale);
    setState(() {});
  }
}
