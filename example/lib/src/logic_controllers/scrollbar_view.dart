// ignore_for_file: public_member_api_docs, sort_constructors_first

part of '../t_pdf_reader_base.dart';

class ScrollbarView extends IScrollbarView {
  ScrollbarView({required super.pdfContext});

  @override
  Widget build(BuildContext mainContext, BoxConstraints constraints) {
    final double thumbWidth = 30;
    final double thumbHeight = 50;
    final maxScroll =
        (pdfContext.state.totalContentHeight - constraints.maxHeight).clamp(
          0.1,
          double.infinity,
        );
    final maxTrackHeight = constraints.maxHeight - thumbHeight;

    double topPos =
        (pdfContext.state.currentScrollOffset / maxScroll) * maxTrackHeight;

    return ValueListenableBuilder(
      valueListenable:
          pdfContext.stateController.tPdfController._scrollbarShowHideNotifier,
      // 💡 context နာမည်ကို innerContext သို့မဟုတ် _ လို့ ပြောင်းလိုက်ပါ
      builder: (innerContext, value, child) {
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
              mainContext,
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
    if (pdfContext.tPdfController.scrollbarWidget != null) {
      return pdfContext.tPdfController.scrollbarWidget!(
        thumbWidth,
        thumbHeight,
      );
    }
    return defaultScrollbarNeon(
      thumbWidth: thumbWidth,
      thumbHeight: thumbHeight,
    );
  }

  void onVerticalDragUpdate(
    BuildContext context,
    DragUpdateDetails details,
    double thumbHeight,
    double maxTrackHeight,
    double maxScroll,
  ) {
    // ၁။ စခရင်တစ်ခုလုံးမှာရှိတဲ့ GestureDetector ရဲ့ RenderBox ကို ရှာတယ်
    final RenderBox renderBox = context.findRenderObject() as RenderBox;

    // ၂။ အပေါ်က Stack သို့မဟုတ် တစ်ပြင်လုံးရဲ့ နောက်ခံ (Parent) ရဲ့ Top-Left ကို ရှာရန်
    final parentLocalPosition = renderBox.globalToLocal(details.globalPosition);

    // ၃။ parentLocalPosition.dy က Thumb နေရာရွေ့ပေမယ့် လိုက်မပြောင်းတော့ဘဲ ငြိမ်နေမှာပါ
    double newOffset = parentLocalPosition.dy - (thumbHeight / 2);
    newOffset = newOffset.clamp(0.0, maxTrackHeight);

    // ၄။ Scroll Offset အသစ် ပြန်တွက်ခြင်း
    double newScrollOffset = (newOffset / maxTrackHeight) * maxScroll;

    pdfContext.stateController.dispatch(
      MouseThumbScrollChanged(newScrollOffset),
    );
  }
}
