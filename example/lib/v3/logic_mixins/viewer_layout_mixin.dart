part of '../t_pdf_render_v3_base.dart';
class PageRange {
  final int index;
  final double start;
  final double end;
  const PageRange({
    required this.index,
    required this.start,
    required this.end,
  });
}

mixin ViewerLayoutMixin on State<TCustomPdfViewer> {
  double _lastScreenWidth = 0.0;
  double _lastZoom = 1.0;
  double baseCanvasWidth = 390.0;

  double get startScrollY;
  double get currentZoom;
  double get totalHeight;
  List<PageRange> get pageOffsetRanges;
  set pageOffsetRanges(List<PageRange> ranges);
  set startScrollY(double scrollY);
  set totalHeight(double totalHeight);

  void buildLayout(BoxConstraints constraints) {
    int backupPageIndex = widget.controller._currentPage - 1; // 0-based index
    double relativeOffset = 0.0;
    double relativeOffsetX = 0.0;

    // လက်ရှိ ရောက်နေတဲ့ Page ရဲ့ အစကနေ လူက ဘယ်လောက်အကွာအဝေးကို ရောက်နေလဲ (Zoom မဝင်ခင် မူရင်းအကွာအဝေးကို ရှာတာပါ)
    if (backupPageIndex >= 0 &&
        backupPageIndex < pageOffsetRanges.length &&
        _lastZoom != 0.0) {
      // Y
      double oldPageStart = pageOffsetRanges[backupPageIndex].start;
      relativeOffset = (startScrollY - oldPageStart) / _lastZoom;
      // X အတွက်
      relativeOffsetX = widget.controller._currentReaderOffsetX / _lastZoom;
    }

    double currentOffset = 0.0;
    pageOffsetRanges = [];

    for (var page in widget.psList) {
      final ratio = page.width / page.height;
      //canvs အတိုင်းယူမယ်
      final pageHeight = baseCanvasWidth / ratio;

      final start = currentOffset * currentZoom;
      final end = (currentOffset + pageHeight) * currentZoom;
      // တစ်ခါတည်း သိမ်းလိုက်မယ်
      pageOffsetRanges.add(
        PageRange(index: page.pageIndex, start: start, end: end),
      );
      //
      currentOffset += pageHeight;
    }
    final originalScreenWidth = constraints.maxWidth;

    //zoom ဝင်ပြီးသား အမြင့်
    totalHeight = currentOffset * currentZoom;
    if (backupPageIndex >= 0 && backupPageIndex < pageOffsetRanges.length) {
      // အသစ်ဆောက်လိုက်တဲ့ Layout ထဲက လက်ရှိ Page ရဲ့ Start အသစ်ကို ယူမယ်
      double newPageStart = pageOffsetRanges[backupPageIndex].start;

      if (_lastZoom != currentZoom) {
        // (က) တကယ်လို့ Zoom ပြောင်းသွားတာဆိုရင် -
        // မူရင်းအကွာအဝေး (relativeOffset) ကို Zoom အသစ်နဲ့ မြှောက်ပြီး Page Start အသစ်ထဲ ပေါင်းထည့်မယ်
        startScrollY = newPageStart + (relativeOffset * currentZoom);
      } else if (_lastScreenWidth != 0.0 &&
          _lastScreenWidth != originalScreenWidth) {
        // (ခ) တကယ်လို့ Screen လှည့်သွားတာ (Width ပြောင်းသွားတာ) ဆိုရင် -
        // အရင်အတိုင်း Screen အချိုးအစားအတိုင်း ညှိပြီး ပေါင်းထည့်မယ်
        double adjustedRelativeOffset =
            (relativeOffset * _lastZoom / _lastScreenWidth) *
            originalScreenWidth;
        startScrollY = newPageStart + adjustedRelativeOffset;
      }
    }

    // ၄။ Bound ကျော်မသွားအောင် အမြဲတမ်း ပိတ်ပေးမယ်
    final maxScroll = totalHeight - constraints.maxHeight;
    startScrollY = startScrollY.clamp(0.0, maxScroll > 0 ? maxScroll : 0.0);

    // left-right scroll အတွက်
    final renderWidth = baseCanvasWidth * currentZoom;

    if (renderWidth > originalScreenWidth) {
      final maxScrollX = (renderWidth - originalScreenWidth) / 2;
      final newOffsetX = relativeOffsetX * currentZoom;

      widget.controller._currentReaderOffsetX = newOffsetX.clamp(
        -maxScrollX,
        maxScrollX,
      );
    } else {
      widget.controller._currentReaderOffsetX = 0.0;
    }
    // send offset y
    if (widget.controller._currentReaderOffsetX != 0.0) {
      widget.controller._pdfReaderEventStreamController.add(
        PdfScreenOffsetXChanged(widget.controller._currentReaderOffsetX),
      );
    }

    _lastZoom = currentZoom;
    _lastScreenWidth = originalScreenWidth;
  }

  
}
