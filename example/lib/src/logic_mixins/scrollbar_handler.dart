part of '../t_pdf_reader_base.dart';

mixin ScrollbarHandler {
  BuildContext get context;
  ReaderState get state;
  ReaderStateController get stateController;
  TPdfController get tPdfController;

  Widget scrollBar(BoxConstraints constraints) {
    final double thumbWidth = 30;
    final double thumbHeight = 50;
    final maxScroll = (state.totalContentHeight - constraints.maxHeight).clamp(
      0.1,
      double.infinity,
    );
    final maxTrackHeight = constraints.maxHeight - thumbHeight;

    double topPos = (state.currentScrollOffset / maxScroll) * maxTrackHeight;
    return ValueListenableBuilder(
      valueListenable:
          stateController.tPdfController._scrollbarShowHideNotifier,
      builder: (context, value, child) {
        if (!value) {
          return SizedBox.shrink();
        }
        return Positioned(
          top: topPos,
          right: 5,
          width: thumbWidth,
          height: thumbHeight,
          child: GestureDetector(
            onVerticalDragUpdate: (details) => onVerticalDragUpdate(
              details,
              thumbHeight,
              maxTrackHeight,
              maxScroll,
            ),
            child: scrollbarWidget(thumbWidth, thumbHeight),
          ),
        );
      },
    );
  }

  Widget scrollbarWidget(double thumbWidth, double thumbHeight) {
    if (tPdfController.scrollbarWidget != null) {
      return tPdfController.scrollbarWidget!(thumbWidth,thumbHeight);
    }
    return defaultScrollbarNeon(
      thumbWidth: thumbWidth,
      thumbHeight: thumbHeight,
    );
  }

  void onVerticalDragUpdate(
    DragUpdateDetails details,
    double thumbHeight,
    double maxTrackHeight,
    double maxScroll,
  ) {
    // ၁။ စခရင်တစ်ခုလုံးမှာရှိတဲ့ GestureDetector ရဲ့ RenderBox ကို ရှာတယ်
    final RenderBox renderBox = context.findRenderObject() as RenderBox;

    // ၂။ အပေါ်က Stack သို့မဟုတ် တစ်ပြင်လုံးရဲ့ နောက်ခံ (Parent) ရဲ့ Top-Left ကို ရှာရန်
    // globalPosition ကနေ တည်ငြိမ်တဲ့ local position တစ်ခုပြောင်းယူခြင်း ဖြစ်ပါတယ်
    final parentLocalPosition = renderBox.globalToLocal(details.globalPosition);

    // ၃။ parentLocalPosition.dy က Thumb နေရာရွေ့ပေမယ့် လိုက်မပြောင်းတော့ဘဲ ငြိမ်နေမှာပါ
    double newOffset = parentLocalPosition.dy - (thumbHeight / 2);
    newOffset = newOffset.clamp(0.0, maxTrackHeight);

    // ၄။ Scroll Offset အသစ် ပြန်တွက်ခြင်း
    double newScrollOffset = (newOffset / maxTrackHeight) * maxScroll;

    // print(
    //   'totalContentHeight: ${state.totalContentHeight} - newOffset: $newScrollOffset',
    // );
    stateController.dispatch(MouseThumbScrollChanged(newScrollOffset));
  }
}
