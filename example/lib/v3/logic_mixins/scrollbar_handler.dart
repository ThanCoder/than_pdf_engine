part of '../t_pdf_render_v3_base.dart';

mixin ScrollbarHandler on State<TCustomPdfViewer> {
  double scrollbarDrapOffset = 0;
  bool _isDragging = false;
  double _currentScrollbarY = 0.0;

  double get totalHeight;
  double get startScrollY;
  double get lastScreenWidth;
  set startScrollY(double x);
  void updateCurrentPageEvent(double screenHeight, double lastScreenWidth);

  Widget scrollBar(double screenHeight) {
    double scrollbarHeight = 40;
    double scrollbarWidth = 10;
    double scrollbarRightPosition = 0;
    Widget scrollWidget = _defaultScrollbar;

    if (widget.controller._customScrollbar != null) {
      final customScroll = widget.controller._customScrollbar!(
        context,
        widget.controller._currentPage,
      );
      scrollbarWidth = customScroll.scrollbarWidth;
      scrollbarHeight = customScroll.scrollbarHeight;
      scrollbarRightPosition = customScroll.scrollbarRightPosition;
      scrollWidget = customScroll.child;
    }

    final double maxScroll = totalHeight - screenHeight;
    final double maxScrollbarTop = screenHeight - scrollbarHeight;

    // ၁။ 🎯 [_isDragging မဟုတ်ခဲရင်] Scrollbar နေရာကို မူရင်းအတိုင်း ပြန်ညှိတဲ့ Math Formula အမှန်
    if (!_isDragging) {
      if (maxScroll > 0) {
        // totalHeight အစား maxScroll (အမြင့်ဆုံးရွေ့နိုင်တဲ့အမြင့်) နဲ့ အချိုးချရပါမယ်
        _currentScrollbarY = (startScrollY / maxScroll) * maxScrollbarTop;
      } else {
        _currentScrollbarY = 0.0;
      }
    }

    return Positioned(
      top: _currentScrollbarY,
      right: scrollbarRightPosition,
      width: scrollbarWidth,
      height: scrollbarHeight,
      child: GestureDetector(
        onVerticalDragStart: (details) {
          if (!widget.controller.isShowScrollbar) return;
          _isDragging = true;
          scrollbarDrapOffset = details.localPosition.dy;
        },
        onVerticalDragEnd: (details) {
          if (!widget.controller.isShowScrollbar) return;
          _isDragging = false;
          setState(() {});
        },
        onVerticalDragUpdate: (details) {
          if (!widget.controller.isShowScrollbar) return;
          setState(() {
            // 🎯 ပြင်ဆင်ချက် ၂: Drag Position ကို တွက်တဲ့အခါ globalPosition ထဲကနေ
            // နှိပ်ခဲ့တဲ့ Scrollbar ရဲ့ Offset ကို နှုတ်ပြီး တွက်ရင် ပိုပြီး Smooth ဖြစ်ပြီး မတုန်တော့ပါဘူး
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            double localTop = renderBox
                .globalToLocal(details.globalPosition)
                .dy;

            // လက်ရှိ ရောက်ရမယ့် Scrollbar ရဲ့ Top Position
            _currentScrollbarY = localTop - scrollbarDrapOffset;

            // Boundary ပိတ်မယ်
            _currentScrollbarY = _currentScrollbarY.clamp(0.0, maxScrollbarTop);

            // Scrollbar နေရာကနေ Screen Scroll Position (startScrollY) ကို ပြန်ပြောင်းလဲတွက်ချက်မယ်
            startScrollY = (_currentScrollbarY / maxScrollbarTop) * maxScroll;
            startScrollY = startScrollY.clamp(0.0, maxScroll);
          });

          // ၄။ 🎯 Scrollbar ဆွဲနေတဲ့အချိန်မှာလည်း လက်ရှိဘယ်နှမျက်နှာ ရောက်နေလဲ ချက်ချင်းသိအောင် လှမ်းခေါ်ပေးရပါမယ်
          updateCurrentPageEvent(screenHeight, lastScreenWidth);
        },
        child: scrollWidget,
      ),
    );
  }
}
