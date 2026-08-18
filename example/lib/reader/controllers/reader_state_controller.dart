import 'dart:async';
import 'dart:math';

import 'package:than_pdf_engine/core/models/page_size.dart';
import 'package:than_pdf_engine_example/reader/controllers/page_offset.dart';
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

  final PageImageCache imageCache = PageImageCache();

  final _con = StreamController<ReaderEvent>.broadcast();
  Stream<ReaderEvent> get stream => _con.stream;
  void addEvent(ReaderEvent event) {
    _con.add(event);
  }

  void updateViewportHeight(double viewportWidth, double viewportHeight) {
    _con.add(UpdateViewort());

    if (recentViewportWidth != viewportWidth) {
      recentViewportWidth = viewportWidth;
      _con.add(UpdateViewortWidth());
      //   // update page width
      //   return;
    }
    // //update page height
    if (recentViewportHeight != viewportHeight) {
      recentViewportHeight = viewportHeight;
      _con.add(UpdateViewortHeight());
      //   return;
    }
    updateVisiablePages();
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
}
