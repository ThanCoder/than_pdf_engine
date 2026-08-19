import 'dart:async';
import 'dart:math';

import 'package:than_pdf_engine/core/models/page_size.dart';
import 'package:than_pdf_engine_example/reader/controllers/page_offset.dart';
import 'package:than_pdf_engine_example/reader/controllers/reader_state.dart';
import 'package:than_pdf_engine_example/reader/controllers/scrollbar_info.dart';
import 'package:than_pdf_engine_example/reader/utils/page_image_cache.dart';
import 'package:than_pdf_engine_example/reader/utils/page_offset_utils.dart';

part 'reader_events.dart';
part 'i_reader_controller.dart';

class ReaderStateController {
  List<PageOffset> visiblePages = [];
  List<PageSize> pages = [];
  List<PageOffset> pageOffsets = [];
  ReaderState state = .new();

  void setConfig() {}

  final _con = StreamController<ReaderEvent>.broadcast();
  Stream<ReaderEvent> get stream => _con.stream;
  void addEvent(ReaderEvent event) {
    _con.add(event);
  }

  //**********************Layout Changed**************************************** */

  void updateViewportHeight(double viewportWidth, double viewportHeight) {
    bool changed = false;

    if (state.recentViewportWidth != viewportWidth) {
      state.recentViewportWidth = viewportWidth;
      _con.add(UpdateViewortWidth());
      changed = true;
    }

    if (state.recentViewportHeight != viewportHeight) {
      state.recentViewportHeight = viewportHeight;
      _con.add(UpdateViewortHeight());
      changed = true;
    }

    if (changed) {
      updateVisiablePages();
    }
  }

  void setOffset(double value) {
    final maxOffset = max(0.0, contentHeight - state.recentViewportHeight);

    state.currentOffset = value.clamp(0.0, maxOffset);

    updateVisiablePages();
  }

  void scrollBy(double dy) {
    final maxOffset = max(0.0, contentHeight - state.recentViewportHeight);
    // print(
    //   'recentViewportHeight: $recentViewportHeight - currentOffset: $currentOffset - maxOffset: $maxOffset',
    // );
    if (maxOffset <= 0) return;
    state.currentOffset = (state.currentOffset + dy).clamp(0.0, maxOffset);

    updateVisiablePages();
  }
  //**********************UI Visiable Page Changed**************************************** */

  void updateVisiablePages() {
    visiblePages = PageOffsetUtils.calculateVisiblePages(
      pages: pageOffsets,
      scrollOffset: state.currentOffset,
      viewportHeight: state.recentViewportHeight,
    );
    // current page event
    final currentPage = getCurrentPage();
    if (currentPage != null && state.page != currentPage) {
      state.page = currentPage;
      _con.add(PageChanged(state.page));
    }

    // 🟢 ပြင်ရန် code
    final scrollInfo = getScrollbarInfo();
    if (scrollInfo != null) {
      if (state.scrollbarInfo == null ||
          state.scrollbarInfo!.thumbTop != scrollInfo.thumbTop ||
          state.scrollbarInfo!.thumbHeight != scrollInfo.thumbHeight) {
        state.scrollbarInfo = scrollInfo;
        _con.add(ScrollbarUiChanged());
      }
    }

    _con.add(UpdateVisiblePages());
  }

  double get contentHeight {
    if (pageOffsets.isEmpty) return 0;
    return pageOffsets.last.bottom.toDouble();
  }

  int? getCurrentPage() {
    final pages = visiblePages;
    if (pages.isEmpty) return null;

    final center = state.currentOffset + state.recentViewportHeight / 2;

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

  //**********************Mobile Scale Handler**************************************** */
  void setMobileScale(double scale, double offsetX, double offsetY) {
    // 1. Zoom မပြောင်းမီ Old Zoom ဖြင့် Viewport Center (Unscaled Content Y) ကို မှတ်ထားပါ
    final oldZoom = state.zoom;
    final viewportCenterY =
        state.currentOffset + (state.recentViewportHeight / 2);
    final contentPositionY = viewportCenterY / oldZoom;

    // 2. Horizontal Offset (X) ကို တိုက်ရိုက် ပေါင်းစပ်ပါ
    state.currentOffsetX = state.currentOffsetX + offsetX;

    // 3. Zoom Factor တွက်ချက်ခြင်း
    if (scale != 1.0) {
      final double scaleDelta = scale - 1.0;
      final double adjustedScale = 1.0 + (scaleDelta * state.zoomSensitivity);

      // Target Zoom အသစ် တွက်ချက်ခြင်း
      final double targetZoom = (state.zoom * adjustedScale).clamp(
        state.minZoom,
        state.maxZoom,
      );

      if (oldZoom != targetZoom) {
        state.zoom = targetZoom;

        // Page Offsets များကို Zoom အသစ်ဖြင့် ပြန်တွက်ပါ
        pageOffsets = PageOffsetUtils.calculatePageOffsets(
          pages,
          zoom: state.zoom,
        );

        // 4. Zoom ပြောင်းသွားသဖြင့် Old Content Position ကို မူတည်၍ Vertical Offset (Y) ကို ပြန်တွက်ပါ
        // Pinch လုပ်နေစဉ် အပေါ်/အောက် ရွှေ့လိုက်သော offsetY Delta ပါ အချိုးကျ ထည့်တွက်ပေးပါမည်
        final newOffsetY =
            (contentPositionY * state.zoom) -
            (state.recentViewportHeight / 2) -
            offsetY;

        final maxOffsetY = max(0.0, contentHeight - state.recentViewportHeight);
        state.currentOffset = newOffsetY.clamp(0.0, maxOffsetY);

        _con.add(ScaleChanged());
      } else {
        // Zoom မပြောင်းဘဲ (min/max ရောက်နေချိန်) လက်ရွှေ့ရုံသက်သက် ဆိုလျှင် offsetY တိုက်ရိုက် ပေါင်းပါမည်
        final maxOffsetY = max(0.0, contentHeight - state.recentViewportHeight);
        state.currentOffset = (state.currentOffset - offsetY).clamp(
          0.0,
          maxOffsetY,
        );
      }
    } else {
      // Scale မပြောင်းဘဲ Drag ဆွဲရုံသက်သက် အခြေအနေ
      final maxOffsetY = max(0.0, contentHeight - state.recentViewportHeight);
      state.currentOffset = (state.currentOffset - offsetY).clamp(
        0.0,
        maxOffsetY,
      );
    }

    // Horizontal Offset (X) ဘက်အတွက် Bounds ထိန်းချုပ်ပေးခြင်း
    if (pageOffsets.isNotEmpty) {
      final pageWidth = pageOffsets.first.width;
      if (pageWidth <= state.recentViewportWidth) {
        state.currentOffsetX = 0.0; // Screen ထက် သေးပါက Center ၌ ထားမည်
      } else {
        final maxOffsetX = (pageWidth - state.recentViewportWidth) / 2;
        state.currentOffsetX = state.currentOffsetX.clamp(
          -maxOffsetX,
          maxOffsetX,
        );
      }
    }

    updateVisiablePages();
  }

  //**********************Zoom Handler**************************************** */
  void setZoom(double value) {
    final targetZoom = value.clamp(state.minZoom, state.maxZoom);

    final oldZoom = state.zoom;
    if (oldZoom == targetZoom) return;

    // 1. Viewport Center Point (Vertical & Horizontal)
    final viewportCenterY =
        state.currentOffset + (state.recentViewportHeight / 2);

    // 2. Unscaled Space သို့ ပြောင်းခြင်း
    final contentPositionY = viewportCenterY / oldZoom;

    // 3. Zoom အသစ် သတ်မှတ်ခြင်း
    state.zoom = targetZoom;

    // 4. Page Offsets ပြန်တွက်ခြင်း
    pageOffsets = PageOffsetUtils.calculatePageOffsets(pages, zoom: state.zoom);

    // 5. Y Offset ကို Center ကျအောင် ပြန်တွက်ပြီး Clamp ခတ်ခြင်း
    final newOffsetY =
        (contentPositionY * state.zoom) - (state.recentViewportHeight / 2);
    final maxOffsetY = max(0.0, contentHeight - state.recentViewportHeight);
    state.currentOffset = newOffsetY.clamp(0.0, maxOffsetY);

    // 6. X Offset (Zoom ပြောင်းသွားသည့်အခါ Horizontal Drag Offset ကို Scale အချိုးအတိုင်း ညှိပေးခြင်း)
    state.currentOffsetX = state.currentOffsetX * (targetZoom / oldZoom);

    // Page က Screen ထက် သေးနေရင် currentOffsetX ကို 0 (Center) သို့ ပြန်ပို့ပေးပါမည်
    if (pageOffsets.isNotEmpty) {
      final pageWidth = pageOffsets.first.width;
      if (pageWidth <= state.recentViewportWidth) {
        state.currentOffsetX =
            0.0; // Screen ထက် သေးရင် အလယ်တည့်တည့် (Center) မှာပဲ ငြိမ်နေမည်
      } else {
        // Screen ထက် ကြီးသွားရင် ဘေးဘောင်များ ကျော်မထွက်အောင် Bounds ခတ်မည်
        final maxOffsetX = (pageWidth - state.recentViewportWidth) / 2;
        state.currentOffsetX = state.currentOffsetX.clamp(
          -maxOffsetX,
          maxOffsetX,
        );
      }
    }

    _con.add(ZoomChanged(state.zoom));
    updateVisiablePages();
  }

  double get fitWidthZoom {
    if (pages.isEmpty || state.recentViewportWidth <= 0) {
      return 1.0;
    }

    final page = pages.first;

    return state.recentViewportWidth / page.width;
  }

  // Page ကို Horizontal Center (အလယ်) ရောက်အောင် OffsetX တွက်ပေးသည့် Function
  void centerPageHorizontally() {
    if (pages.isEmpty || state.recentViewportWidth <= 0) return;

    final page = pages.first;

    // လက်ရှိ Zoom Factor နဲ့ Page ရဲ့ အကျယ် (Scaled Page Width)
    final scaledPageWidth = page.width * state.zoom;

    // Screen အကျယ်နဲ့ Page အကျယ် ခြားနားချက်၏ တစ်ဝက်သည် Horizontal Center Offset ဖြစ်သည်
    state.currentOffsetX = (state.recentViewportWidth - scaledPageWidth) / 2;

    updateVisiablePages();
  }

  // Fit Width သို့ Zoom ဆွဲပြီး Screen ရဲ့ Center တည့်တည့်သို့ ပို့ပေးသည့် Function
  void fitToWidthAndCenter() {
    if (pages.isEmpty || state.recentViewportWidth <= 0) return;

    // 1. Zoom ကို Fit Width Zoom ပြောင်းပေးပါ
    state.zoom = fitWidthZoom;

    // 2. Page Offsets များကို Zoom အသစ်ဖြင့် ပြန်တွက်ပါ
    pageOffsets = PageOffsetUtils.calculatePageOffsets(pages, zoom: state.zoom);

    // 3. Fit Width အခြေအနေမှာ OffsetX ကို Center ကျအောင် 0 ထားပါ (သို့မဟုတ် အထက်ပါ formula သုံးပါ)
    final scaledPageWidth = pages.first.width * state.zoom;
    state.currentOffsetX = (state.recentViewportWidth - scaledPageWidth) / 2;

    updateVisiablePages();
  }

  //**********************Scrollbar**************************************** */

  void scrollByScrollbar(double dy) {
    final info = state.scrollbarInfo;
    if (info == null) return;

    final maxOffset = contentHeight - state.recentViewportHeight;
    final maxThumbOffset =
        state.scrollbarHeight -
        info.thumbHeight; // Dynamic Thumb Height ကို သုံးရပါမည်

    if (maxThumbOffset <= 0) return;

    final delta = (dy / maxThumbOffset) * maxOffset;
    scrollBy(delta);
  }

  void setScrollbarHeight(double height) {
    state.scrollbarHeight = height;
  }

  ScrollbarInfo? getScrollbarInfo() {
    if (contentHeight <= state.recentViewportHeight ||
        state.scrollbarHeight <= 0) {
      return null;
    }

    final maxOffset = contentHeight - state.recentViewportHeight;
    if (maxOffset <= 0) return null;

    final thumbHeight = max(
      state.scrollbarThumbHeight,
      state.scrollbarHeight * state.recentViewportHeight / contentHeight,
    );

    final maxThumbOffset = state.scrollbarHeight - thumbHeight;

    // thumbTop မကျော်သွားစေရန် clamp ခတ်ပေးပါ
    final thumbTop = ((state.currentOffset / maxOffset) * maxThumbOffset).clamp(
      0.0,
      maxThumbOffset,
    );

    return ScrollbarInfo(thumbTop: thumbTop, thumbHeight: thumbHeight);
  }

  //**********************Page Jump**************************************** */
  void jumpPageIndex(int pageIndex) {
    final index = pageOffsets.indexWhere((e) => e.pageIndex == pageIndex);
    if (index == -1) return;
    final p = pageOffsets[index];
    state.currentOffset = p.top;

    updateVisiablePages();
  }

  double getPageOffsetY(int pageIndex) {
    final index = pageOffsets.indexWhere((e) => e.pageIndex == pageIndex);
    if (index == -1) return -1;
    return pageOffsets[index].top;
  }
}
