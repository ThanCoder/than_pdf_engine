import 'package:than_pdf_engine/core/types.dart';
import 'package:than_pdf_engine_example/reader_v4/core/pdf_reader_state.dart';

class PdfLayoutEngine {
  /// ၁။ စာမျက်နှာအားလုံးရဲ့ တည်နေရာကို တွက်ချက်ခြင်း
  static List<PageOffset> calculatePageOffsets({
    required List<PageSize> pageSizeList,
    required double zoomFactor,
  }) {
    final List<PageOffset> offsets = [];
    double totalHeight = 0;

    for (var i = 0; i < pageSizeList.length; i++) {
      final page = pageSizeList[i];
      double renderWidth = page.width * zoomFactor;
      double renderHeight = page.height * zoomFactor;

      offsets.add(
        PageOffset(
          startOffset: totalHeight,
          endOffset: totalHeight + renderHeight,
          pageIndex: i,
          width: renderWidth,
          height: renderHeight,
        ),
      );
      totalHeight += renderHeight;
    }
    return offsets;
  }

  /// ၂။ မျက်နှာပြင်ပေါ်မှာ မြင်ရမယ့် စာမျက်နှာတွေကိုပဲ စစ်ထုတ်ခြင်း (Virtualization)
  static List<PageOffset> getVisiblePages({
    required List<PageOffset> allPageOffsets,
    required double scrollOffset,
    required double viewportHeight,
    required double zoomFactor,
  }) {
    if (allPageOffsets.isEmpty) return [];

    // Binary Search ဖြင့် ပထမဆုံး မြင်ရသော စာမျက်နှာကို ရှာဖွေခြင်း
    final currentIndex = _firstVisibleIndex(allPageOffsets, scrollOffset);

    // Zoom အလိုက် Cache စာမျက်နှာ အရေအတွက် တွက်ချက်ခြင်း
    int cacheCount = (3 / zoomFactor).ceil().clamp(3, 15);

    final startIndex = (currentIndex - cacheCount).clamp(
      0,
      allPageOffsets.length - 1,
    );
    final endIndex = (currentIndex + cacheCount).clamp(
      0,
      allPageOffsets.length - 1,
    );

    return allPageOffsets.sublist(startIndex, endIndex + 1);
  }

  static int _firstVisibleIndex(List<PageOffset> offsets, double scrollOffset) {
    int low = 0;
    int high = offsets.length - 1;
    while (low <= high) {
      final mid = low + (high - low) ~/ 2;
      if (offsets[mid].endOffset < scrollOffset) {
        low = mid + 1;
      } else if (offsets[mid].startOffset > scrollOffset) {
        high = mid - 1;
      } else {
        return mid;
      }
    }
    return low.clamp(0, offsets.length - 1);
  }
}
