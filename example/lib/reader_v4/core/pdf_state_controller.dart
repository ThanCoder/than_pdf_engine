import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:than_pdf_engine/than_pdf_engine.dart';
import 'package:than_pdf_engine_example/reader_v4/core/pdf_layout_engine.dart';
import 'package:than_pdf_engine_example/reader_v4/core/pdf_reader_events.dart';
import 'package:than_pdf_engine_example/reader_v4/core/pdf_reader_state.dart';

class PdfStateController {
  final _stateStreamController = StreamController<PdfReaderState>.broadcast();
  Stream<PdfReaderState> get stateStream => _stateStreamController.stream;

  late PdfReaderState _state;
  PdfReaderState get state => _state;
  final List<PageSize> pageSizeList;

  PdfStateController(this.pageSizeList) {
    _state = PdfReaderState(pageOffsets: []);
  }

  void dispatch(PdfReaderEvent event) {
    if (event is PdfLayoutChanged) {
      _buildLayout(event.constraints);
    } else if (event is PdfScrollChanged) {
      _handleScroll(event);
    } else if (event is PdfScrollYSetDirect) {
      _handelScrollXDirect(event);
    } else if (event is PdfZoomIn) {
      _handleButtonZoom(scaleStep: 0.1, viewportSize: event.viewportSize);
    } else if (event is PdfZoomOut) {
      _handleButtonZoom(scaleStep: -0.1, viewportSize: event.viewportSize);
    } else if (event is PdfScaleChanged) {
      _handleScaleEvents(event);
    } else if (event is PdfPageJump) {
      _handlePageJump(event);
    } else if (event is PdfZoomChanged) {
      _handleZoom(event);
    }
  }

  void _handleZoom(PdfZoomChanged event) {
    if (_state.lastConstraints == null) return;

    double newZoom = (event.baseZoom * event.scale).clamp(
      _state.zoomMinScale,
      _state.zoomMaxScale,
    );
    if (newZoom == _state.zoomFactor) return;

    double zoomRatio = newZoom / _state.zoomFactor;

    // မျက်နှာပြင်ရဲ့ အလယ်ဗဟိုကို ရှာဖွေခြင်း
    double centerX = _state.lastConstraints!.maxWidth / 2;
    double centerY = _state.lastConstraints!.maxHeight / 2;

    // 💡 [အဓိက ပြင်ဆင်ချက်]
    // Formula ထဲက အပေါင်း/အနှုတ် (Sign) ကို ညာဘက်လွင့်မထွက်အောင် အခုလို ပြောင်းလဲပေးရပါမယ်
    double newScrollOffsetY =
        (event.focalPoint.dy + _state.currentScrollOffsetY) * zoomRatio -
        event.focalPoint.dy;

    // ညာဘက်ကို လွင့်ထွက်သွားတာကို ထိန်းချုပ်ဖို့ ဤနေရာတွင် အနှုတ် လက္ခဏာကို အချိုးကျ ညှိပေးလိုက်ပါပြီ
    double newScrollOffsetX =
        (centerX - _state.currentScrollOffsetX) * zoomRatio - centerX;
    newScrollOffsetX = -newScrollOffsetX; // ဝင်ရိုး ပြောင်းပြန်ပြန်လှန်ခြင်း

    // Boundary Limit အတွက် Clamp လုပ်ခြင်း
    double maxScrollOffsetY =
        (_state.totalContentHeight - _state.lastConstraints!.maxHeight).clamp(
          0.0,
          double.infinity,
        );

    _state = _state.copyWith(
      zoomFactor: newZoom,
      currentScrollOffsetY: newScrollOffsetY.clamp(0.0, maxScrollOffsetY),
      currentScrollOffsetX: newScrollOffsetX, // 💡 အသစ်ရလာတဲ့ တည်ငြိမ် Offset X
    );

    _buildLayout(state.lastConstraints!);
  }

  void _handleScaleEvents(PdfScaleChanged event) {
    if (state.lastConstraints == null) return;
    _state = _state.copyWith(
      currentScrollOffsetX: event.offsetX,
      currentScrollOffsetY: event.offsetY,
      zoomFactor: event.zoom,
    );
    _buildLayout(state.lastConstraints!);
    // _buildVisiblePagesList();
  }

  void _handlePageJump(PdfPageJump page) {
    int targetIndex = page.pageIndex;
    // ၁။ ကာကွယ်ရေးစနစ်: pageOffsets မရှိရင် သို့မဟုတ် index ကျော်နေရင် ဘာမှမလုပ်ဘဲ ပြန်ထွက်မယ်
    if (_state.pageOffsets.isEmpty) return;

    // Index Bounds ကို ညှိပေးခြင်း (ဥပမာ - စာမျက်နှာထက် ကျော်မသွားအောင်)
    final clampedIndex = targetIndex.clamp(0, _state.pageOffsets.length - 1);

    // ၂။ 💡 အဓိက သော့ချက် - ပန်းတိုင်စာမျက်နှာရဲ့ စတင်မည့် Offset (Y-coordinate) ကို ရှာသည်
    final targetPage = _state.pageOffsets[clampedIndex];
    double targetOffset = targetPage.startOffset;

    // ၃။ အောက်ဆုံးစာမျက်နှာတွေဆိုရင် Scroll Boundary ကျော်မသွားအောင် Clamp ပြန်လုပ်ပေးရမယ်
    if (_state.lastConstraints != null) {
      double maxScrollExtent =
          (_state.totalContentHeight - _state.lastConstraints!.maxHeight).clamp(
            0.0,
            double.infinity,
          );
      targetOffset = targetOffset.clamp(0.0, maxScrollExtent);
    }

    // ၄။ State ကို update လုပ်ပြီး visible pages ကို ပြန်တွက်ခိုင်းမည်
    _state = _state.copyWith(
      currentScrollOffsetY: targetOffset,
      currentScrollOffsetX: page.offsetX,
      zoomFactor: page.zoom,
    );
    if (page.offsetX != null || page.zoom != null) {
      _buildLayout(state.lastConstraints!);
    } else {
      _buildVisiblePagesList();
    }
  }

  void _handleButtonZoom({
    required double scaleStep,
    required Size viewportSize,
  }) {
    // ၁။ Zoom Factor အသစ်ကို တွက်ချက်သည်
    double newZoom = (_state.zoomFactor + scaleStep).clamp(
      _state.zoomMinScale,
      _state.zoomMaxScale,
    );
    _state = _state.copyWith(zoomFactor: newZoom);

    // Layout Engine ကို ခေါ်ပြီး visible pages ပြန်တွက်ခိုင်းမည်
    _buildLayout(
      BoxConstraints(
        maxWidth: viewportSize.width,
        maxHeight: viewportSize.height,
      ),
    );
  }

  void _handelScrollXDirect(PdfScrollYSetDirect event) {
    _state = _state.copyWith(
      currentScrollOffsetY: event.exactOffset.clamp(
        0.0,
        _state.totalContentHeight,
      ),
    );
    _buildVisiblePagesList();
  }

  /// ၂။ သာမန် Scroll ဆွဲနေချိန် (Layout တွက်စရာမလို၊ Visible ပဲ ပြန်ရှာမည်)
  void _handleScroll(PdfScrollChanged event) {
    _state = _state.copyWith(
      currentScrollOffsetY: (_state.currentScrollOffsetY + event.deltaY).clamp(
        0.0,
        _state.totalContentHeight,
      ),
    );

    // 💡 Scroll ဆွဲရင်လည်း Visible Pages List ကို ချက်ချင်း ပြန်တွက်သည်
    _buildVisiblePagesList();
  }

  void _buildLayout(BoxConstraints constraints) {
    if (pageSizeList.isEmpty) return;

    // (က) Pure Engine ထံမှ စာမျက်နှာမြေပုံ အသစ်ကို တွက်ထုတ်ခိုင်းသည်
    final newOffsets = PdfLayoutEngine.calculatePageOffsets(
      pageSizeList: pageSizeList, // Event ထဲကနေ မူရင်း PDF sizes ကို ယူမယ်
      zoomFactor: _state.zoomFactor,
    );

    double totalHeight = newOffsets.fold(0, (sum, item) => sum + item.height);

    // (ခ) Layout Data များကို State ထဲသို့ အရင် သိမ်းဆည်းလိုက်သည်
    _state = _state.copyWith(
      pageOffsets: newOffsets,
      totalContentHeight: totalHeight,
      lastConstraints: constraints,
    );

    // (ဂ) 💡 Layout တွက်ပြီးတာနဲ့ နောက်ဆက်တွဲအဖြစ် Visible Pages ကို ချက်ချင်း ဆက်ခေါ်သည်
    _buildVisiblePagesList();
  }

  void _buildVisiblePagesList() {
    if (_state.lastConstraints == null) return;

    // လက်ရှိ ရှိပြီးသား pageOffsets မြေပုံပေါ်မူတည်ပြီး visible pages ကို စစ်ထုတ်သည်
    final visible = PdfLayoutEngine.getVisiblePages(
      allPageOffsets: _state.pageOffsets,
      scrollOffset: _state.currentScrollOffsetY,
      viewportHeight: _state.lastConstraints!.maxHeight,
      zoomFactor: _state.zoomFactor,
    );

    // State ကို အပြီးသတ် Update လုပ်ပြီး Stream ထဲသို့ ပို့လွှတ် (emit) သည်
    _state = _state.copyWith(visiblePages: visible);
    _stateStreamController.add(_state);
  }

  void dispose() {
    _stateStreamController.close();
  }
}

/*

  void calculateLayout(BoxConstraints constraints) {
    if (widget.pageSizeList.isEmpty) return;

    // Constraints ရော Zoom ရော မပြောင်းလဲရင် ကျော်သွားမယ်
    // (ဒီနေရာမှာ Layout လှည့်ရင် constraints.maxWidth ပြောင်းမှာဖြစ်လို့ အောက်က save/restore ထဲ ဝင်သွားပါလိမ့်မယ်)
    if (_lastConstraints?.maxWidth == constraints.maxWidth &&
        _lastConstraints?.maxHeight == constraints.maxHeight &&
        _lastZoomFactor == zoomFactor &&
        pageOffsets.isNotEmpty) {
      return;
    }
    // if (_isScaling) return;

    // Layout ပြောင်းလဲချိန်မှာ Scroll Position မလွဲအောင် သိမ်းဆည်းမယ်
    saveCurrentState();

    _lastConstraints = constraints;
    _lastZoomFactor = zoomFactor;
    pageOffsets.clear();

    totalContentHeight = 0;

    for (var i = 0; i < widget.pageSizeList.length; i++) {
      final page = widget.pageSizeList[i];

      // 💡 အဓိက ပြင်ဆင်ချက်: Screen Width နဲ့ ဘာမှ မဆိုင်တော့ဘဲ
      // မူရင်း PDF Size ကို Zoom Factor နဲ့ပဲ တိုက်ရိုက်မြှောက်ပါတော့တယ်
      double renderWidth = page.width * zoomFactor;
      double renderHeight = page.height * zoomFactor;

      pageOffsets.add(
        PageOffset(
          startOffset: totalContentHeight,
          endOffset: totalContentHeight + renderHeight,
          pageIndex: i,
          width: renderWidth,
          height: renderHeight,
        ),
      );

      totalContentHeight += renderHeight;
    }

    // နေရာဟောင်းကို အချိုးကျ ပြန်ရှာမယ်
    restoreCurrentState();
    buildVisiablePages(constraints);
  }

  List<PageOffset> visiablePageList = [];
  void buildVisiablePages(BoxConstraints constraints) {
    if (pageOffsets.isEmpty) return;
    // ၁။ မျက်နှာပြင်ပေါ်မှာ လက်ရှိ တကယ်မြင်နေရတဲ့ ပထမဆုံး စာမျက်နှာ Index (Current Page) ကို ရှာမယ်
    final currentIndex = _firstVisiableIndex(currentScrollOffset);

    // ရှေ့/နောက် ပြသချင်တဲ့ စာမျက်နှာ အရေအတွက် (သင်လိုချင်တာက ၃ ခုစီ)
    // 💡 လျှို့ဝှက်ချက်: Zoom သေးရင် သေးသလောက် စာမျက်နှာတွေ ပိုယူပေးဖို့ တွက်ချက်မယ်
    // ဥပမာ - zoomFactor က 1.0 ဆိုရင် cache က 3 စောင်၊ zoomFactor က 0.3 ဆိုရင် cache က 10 စောင် ဖြစ်သွားပါမယ်
    int cacheCount = (3 / zoomFactor).ceil().clamp(3, 15);

    // ၂။ စတင်မည့် Index ကို တွက်ချက်မယ် (Current ရဲ့ အပေါ် ၃ ခု၊ အနည်းဆုံး 0)
    final startIndex = (currentIndex - cacheCount).clamp(
      0,
      pageOffsets.length - 1,
    );

    // ၃။ အဆုံးသတ်မည့် Index ကို တွက်ချက်မယ် (Current ရဲ့ အောက် ၃ ခု၊ အများဆုံး စာမျက်နှာ စုစုပေါင်းအရေအတွက်)
    final endIndex = (currentIndex + cacheCount).clamp(
      0,
      pageOffsets.length - 1,
    );

    // ၄။ သတ်မှတ်ထားတဲ့ ပတ်ပတ်လည် Range (startIndex မှ endIndex အထိ) ကိုပဲ Loop ပတ်ပြီး ထည့်ပေးမယ်
    for (var i = startIndex; i <= endIndex; i++) {
      visiablePageList.add(pageOffsets[i]);
    }
  }

  int _firstVisiableIndex(double scrollOffset) {
    int low = 0;
    int height = pageOffsets.length - 1;
    while (low <= height) {
      final mid = low + (height - low) ~/ 2;
      final page = pageOffsets[mid];
      if (page.endOffset < scrollOffset) {
        low = mid + 1;
      } else if (page.startOffset > scrollOffset) {
        height = mid - 1;
      } else {
        return mid;
      }
    }
    return low.clamp(0, pageOffsets.length - 1);
  }

  void saveCurrentState() {
    if (pageOffsets.isEmpty) return;
    final currentPage = pageOffsets[_firstVisiableIndex(currentScrollOffset)];
    final internalOffsetY = currentScrollOffset - currentPage.startOffset;
    final pageOffsetYRatio = internalOffsetY / currentPage.height;
    currentPageScale = currentPageScale.copyWith(
      offsetY: pageOffsetYRatio,
      pageIndex: currentPage.pageIndex,
    );
  }

  void restoreCurrentState() {
    final targetIndex = currentPageScale.pageIndex;

    if (pageOffsets.isEmpty || targetIndex >= pageOffsets.length) return;

    final newPage = pageOffsets[targetIndex];

    // Ratio အတိုင်း Pixel ပြန်ရှာမယ်
    double ratioY = currentPageScale.offsetY.isFinite
        ? currentPageScale.offsetY
        : 0.0;
    double actualPixelOffsetY = newPage.height * ratioY;

    double targetScrollOffset = newPage.startOffset + actualPixelOffsetY;

    if (targetScrollOffset.isFinite) {
      // 💡 အဓိက လျှို့ဝှက်ချက် - မျက်နှာပြင်အမြင့်သစ်အရ အများဆုံး Scroll လို့ရမယ့် Limit အသစ်ကို ပြန်တွက်ရပါမယ်
      // _lastConstraints က LayoutBuilder ကနေ ရလာတဲ့ လက်ရှိ screen size ဖြစ်ပါတယ်
      final maxScrollExtent =
          (totalContentHeight - (_lastConstraints?.maxHeight ?? 0.0)).clamp(
            0.0,
            double.infinity,
          );

      // ရလာတဲ့ offset ကို bounds ကျော်မသွားအောင် ညှိလိုက်ရင် လုံးဝ မပြောင်းလဲတော့ပါဘူး
      currentScrollOffset = targetScrollOffset.clamp(0.0, maxScrollExtent);
    } else {
      currentScrollOffset = 0.0;
    }

    currentPageScale = PageScale(
      offsetX: 0,
      offsetY: ratioY,
      pageIndex: targetIndex,
    );
  }
 */
