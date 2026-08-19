import 'dart:async';
import 'dart:math';

import 'package:than_pdf_engine/core/models/page_size.dart';
import 'package:than_pdf_engine_example/reader/controllers/page_offset.dart';
import 'package:than_pdf_engine_example/reader/controllers/reader_state.dart';
import 'package:than_pdf_engine_example/reader/utils/page_image_cache.dart';
import 'package:than_pdf_engine_example/reader/utils/page_offset_utils.dart';

part 'reader_events.dart';

class ReaderStateController {
  double currentOffset = 0;
  List<PageOffset> visiblePages = [];
  List<PageSize> pages = [];
  List<PageOffset> pageOffsets = [];
  double totalOffset = 0;
  double recentViewportHeight = 0;
  double recentViewportWidth = 0;
  bool scrollbarDragging = false;
  double zoom = 1.0;
  int totalPage = 0;
  int page = 0;
  ScrollbarInfo? scrollbarInfo;
  double scrollbarThumbHeight = 40;
  double scrollbarHeight = 0;

  final PageImageCache imageCache = PageImageCache();

  final _con = StreamController<ReaderEvent>.broadcast();
  Stream<ReaderEvent> get stream => _con.stream;
  void addEvent(ReaderEvent event) {
    _con.add(event);
  }

  void updateViewportHeight(double viewportWidth, double viewportHeight) {
    bool changed = false;

    if (recentViewportWidth != viewportWidth) {
      recentViewportWidth = viewportWidth;
      _con.add(UpdateViewortWidth());
      changed = true;
    }

    if (recentViewportHeight != viewportHeight) {
      recentViewportHeight = viewportHeight;
      _con.add(UpdateViewortHeight());
      changed = true;
    }

    if (changed) {
      updateVisiablePages();
    }
  }

  void setOffset(double value) {
    final maxOffset = max(0.0, contentHeight - recentViewportHeight);

    currentOffset = value.clamp(0.0, maxOffset);

    updateVisiablePages();
  }

  void scrollBy(double dy) {
    final maxOffset = max(0.0, totalOffset - recentViewportHeight);

    currentOffset = (currentOffset + dy).clamp(0.0, maxOffset);

    // print(
    //   'currentOffset: $currentOffset '
    //   '- maxOffset: $maxOffset '
    //   '- dy: $dy',
    // );
    updateVisiablePages();
  }

  void updateVisiablePages() {
    visiblePages = PageOffsetUtils.calculateVisiblePages(
      pages: pageOffsets,
      scrollOffset: currentOffset,
      viewportHeight: recentViewportHeight,
    );
    // current page event
    final currentPage = getCurrentPage();
    if (currentPage != null && page != currentPage) {
      page = currentPage;
      _con.add(PageChanged(page));
    }

    // scrollbar
    final scrollInfo = getScrollbarInfo();
    if (scrollInfo != null) {
      final current = scrollbarInfo;
      // current ရှိနေရင်ပေါ့
      if (current != null && current.thumbTop != scrollInfo.thumbTop) {
        scrollbarInfo = scrollInfo;
        _con.add(ScrollbarUiChanged());
      } else {
        // မရှိဘူး တိုက်ရိုက်ထည့်
        scrollbarInfo = scrollInfo;
        _con.add(ScrollbarUiChanged());
      }
    }

    _con.add(UpdateVisiblePages());
  }

  void setZoom(double value) {
    final oldZoom = zoom;
    if (oldZoom == value) return;

    // Keep viewport center stable.
    final viewportCenter = currentOffset + recentViewportHeight / 2;

    final contentPosition = viewportCenter / oldZoom;

    zoom = value;

    pageOffsets = PageOffsetUtils.calculatePageOffsets(pages, zoom: zoom);

    currentOffset = contentPosition * value - recentViewportHeight / 2;
    // delete cache
    // imageCache.clear();
    _con.add(ZoomChanged(zoom));
    updateVisiablePages();
  }

  double get contentHeight {
    if (pageOffsets.isEmpty) return 0;
    return pageOffsets.last.bottom.toDouble();
  }

  double get fitWidthZoom {
    if (pages.isEmpty || recentViewportWidth <= 0) {
      return 1.0;
    }

    final page = pages.first;

    return recentViewportWidth / page.width;
  }

  int? getCurrentPage() {
    final pages = visiblePages;
    if (pages.isEmpty) return null;

    final center = currentOffset + recentViewportHeight / 2;

    PageOffset closest = pages.first;
    var minDistance = double.infinity;

    for (final page in pages) {
      final pageCenter = (page.top + page.bottom) / 2;
      final distance = (pageCenter - center).abs();

      if (distance < minDistance) {
        minDistance = distance;
        closest = page;
      }
    }

    return closest.pageIndex;
  }

  //**********************Scrollbar**************************************** */
  void scrollByScrollbar(double dy) {
    final maxOffset = contentHeight - recentViewportHeight;

    final maxThumbOffset = scrollbarHeight - scrollbarThumbHeight;

    if (maxThumbOffset <= 0) return;

    final delta = dy / maxThumbOffset * maxOffset;

    scrollBy(delta);
  }

  void setScrollbarHeight(double height) {
    scrollbarHeight = height;
  }

  ScrollbarInfo? getScrollbarInfo() {
    if (contentHeight <= recentViewportHeight || scrollbarHeight <= 0) {
      return null;
    }

    final thumbHeight = max(
      scrollbarThumbHeight,
      scrollbarHeight * recentViewportHeight / contentHeight,
    );

    final maxOffset = contentHeight - recentViewportHeight;

    final maxThumbOffset = scrollbarHeight - thumbHeight;

    final thumbTop = (currentOffset / maxOffset) * maxThumbOffset;

    return ScrollbarInfo(thumbTop: thumbTop, thumbHeight: thumbHeight);
  }
}
