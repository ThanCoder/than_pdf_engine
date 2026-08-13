import 'package:than_pdf_engine_example/src/reader/page_offset.dart';
import 'package:than_pdf_engine/core/types.dart';

class ReaderLayoutEngine {
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
    final firstIndex = _firstVisibleIndex(allPageOffsets, scrollOffset);

    // ၂။ ပြင်ဆင်ရန် - နောက်ဆုံး (အောက်ခြေ) မြင်ရသော စာမျက်နှာကို ရှာခြင်း
    final bottomOffset = scrollOffset + viewportHeight;
    final lastIndex = _lastVisibleIndex(
      allPageOffsets,
      bottomOffset,
      startingFrom: firstIndex,
    );

    // Zoom အလိုက် Cache စာမျက်နှာ အရေအတွက် တွက်ချက်ခြင်း
    int cacheCount = (3 / zoomFactor).ceil().clamp(3, 15);

    // ၃။ ပထမဆုံးကော နောက်ဆုံးကောကိုမှ cacheCount အပေါ်အောက် ထပ်ပေါင်းပေးခြင်း
    final startIndex = (firstIndex - cacheCount).clamp(
      0,
      allPageOffsets.length - 1,
    );
    final endIndex = (lastIndex + cacheCount).clamp(
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

  // ထပ်ထည့်ပေးရမည့် အောက်ခြေစာမျက်နှာရှာသည့် Binary Search Function
  static int _lastVisibleIndex(
    List<PageOffset> offsets,
    double bottomOffset, {
    required int startingFrom,
  }) {
    int low = startingFrom;
    int high = offsets.length - 1;

    while (low <= high) {
      final mid = low + (high - low) ~/ 2;

      if (offsets[mid].startOffset > bottomOffset) {
        high = mid - 1;
      } else if (offsets[mid].endOffset < bottomOffset) {
        low = mid + 1;
      } else {
        return mid;
      }
    }
    return high.clamp(0, offsets.length - 1);
  }

  /// Screen ရဲ့ အလယ်တည့်တည့်မှာ ရောက်နေတဲ့ စာမျက်နှာ Index ကို ရှာဖွေခြင်း
  static int getCurrentCenterPageIndex({
    required List<PageOffset> allPageOffsets,
    required double scrollOffset,
    required double viewportHeight,
  }) {
    if (allPageOffsets.isEmpty) return 0;

    // စခရင်ရဲ့ အလယ်ဗဟိုမှတ် (Center Line) နေရာကို တွက်ချက်ခြင်း
    final double centerOffset = scrollOffset + (viewportHeight / 2);

    int low = 0;
    int high = allPageOffsets.length - 1;

    while (low <= high) {
      final mid = low + (high - low) ~/ 2;
      final page = allPageOffsets[mid];

      // အလယ်ဗဟိုမှတ်က ဒီစာမျက်နှာရဲ့ အစနဲ့ အဆုံးကြားထဲမှာ ရှိနေရင် အဲဒါ Current Page ပဲ
      if (centerOffset >= page.startOffset && centerOffset <= page.endOffset) {
        return page.pageIndex;
      } else if (page.endOffset < centerOffset) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    // ရှာမတွေ့ရင် (ဥပမာ- bound ကျော်နေရင်) အနီးစပ်ဆုံး index ကို clamp လုပ်ပေးမယ်
    return low.clamp(0, allPageOffsets.length - 1);
  }
}
