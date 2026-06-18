part of '../t_pdf_render_v3_base.dart';

mixin ViewerPageBuildHandler on State<TCustomPdfViewer> {
  double get baseCanvasWidth;
  Map<int, bool> get visiablePages;
  double get currentZoom;
  List<PageRange> get pageOffsetRanges;
  double get startScrollY;
  Widget scrollBar(double maxHeight);
  Widget animatedPageItem(int index);
  Widget footerPageItem(int index, double renderWidth);

  Widget buildPageItems(BoxConstraints constraints) {
    return Container(
      color: Colors.grey[100],
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      child: Stack(
        children: [
          // 🚀 Cache ထဲမှာ တကယ်ရှိတဲ့ ၁၁ ရွက်ပဲ Render လုပ်တော့မယ်
          for (int activeIndex in visiablePages.keys) ...[
            _buildPageItem(activeIndex, constraints.maxWidth),
          ],
          // scrollbar
          if (widget.controller._showScrollbar)
            scrollBar(constraints.maxHeight),
        ],
      ),
    );
  }

  Widget _buildPageItem(int index, double screenWidth) {
    final page = widget.psList[index];
    final ratio = page.width / (page.height);

    // ၁။ 🎯 Render လုပ်မယ့် Width နဲ့ Height ကို တွက်ခြင်း
    // buildLayout က တွက်ချက်ပုံစံအတိုင်း ကွက်တိဖြစ်အောင် တွက်ထားပါတယ်
    final renderWidth = baseCanvasWidth * currentZoom;
    final pageHeight = (baseCanvasWidth / ratio) * currentZoom;

    final topPosition = pageOffsetRanges[index].start - startScrollY;

    // စာရွက်ရဲ့ မူလ အလယ်ဗဟိုနေရာ (ဥပမာ - (400 - 600) / 2 = -100)
    final baseLeft = (screenWidth - renderWidth) / 2;

    // 🔥 -100 ထဲကနေ လက်နဲ့ဆွဲထားတဲ့ _startScrollX ကို နုတ်ပေးခြင်းဖြင့် နေရာမှန်ကို ရောက်သွားပါမယ်
    final leftPosition = baseLeft - widget.controller._currentReaderOffsetX;

    return Positioned(
      left: leftPosition,
      top: topPosition,
      width: renderWidth,
      height: pageHeight,
      child: Column(
        children: [
          Expanded(child: animatedPageItem(index)),
          footerPageItem(index, renderWidth),
        ],
      ),
    );
  }
}
