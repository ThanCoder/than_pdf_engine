import 'dart:math';

import 'package:than_pdf_engine/core/models/page_size.dart';
import 'package:than_pdf_engine_example/reader/controllers/page_offset.dart';

class PageOffsetUtils {
  static List<PageOffset> calculatePageOffsets(
    List<PageSize> pages, {
    required double zoom,
    int spacing = 0,
  }) {
    final result = <PageOffset>[];

    double offset = 0;

    for (final page in pages) {
      final top = offset;
      final width = page.width * zoom;
      final height = page.height * zoom;
      final bottom = top + height;

      result.add(
        PageOffset(
          pageIndex: page.page,
          width: width,
          height: height,
          top: top,
          bottom: bottom,
        ),
      );

      offset = bottom + spacing;
    }

    return result;
  }

  static List<PageOffset> calculateVisiblePages({
    required List<PageOffset> pages,
    required double scrollOffset,
    required double viewportHeight,
  }) {
    final viewportBottom = scrollOffset + viewportHeight;

    final firstVisible = findFirstVisiblePage(pages, scrollOffset);

    // Find last visible page.
    var lastVisible = firstVisible;

    for (var i = firstVisible; i < pages.length; i++) {
      final page = pages[i];

      if (page.top >= viewportBottom) {
        break;
      }

      lastVisible = i;
    }

    // Keep 2 pages above and 2 pages below viewport.
    final start = max(0, firstVisible - 2);
    final end = min(pages.length, lastVisible + 3);

    return pages.sublist(start, end);
  }

  /// binary search
  static int findFirstVisiblePage(List<PageOffset> pages, double viewportTop) {
    var low = 0;
    var high = pages.length - 1;

    while (low <= high) {
      final mid = (low + high) >> 1;
      final page = pages[mid];

      if (page.bottom <= viewportTop) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    return low;
  }
}
