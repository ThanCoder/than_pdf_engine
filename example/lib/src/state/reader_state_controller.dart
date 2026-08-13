part of '../t_pdf_reader_base.dart';

class ReaderStateController {
  final _controller = StreamController<ReaderState>.broadcast();
  Stream<ReaderState> get stateStream => _controller.stream;
  late ReaderState _state;
  ReaderState get state => _state;
  late List<PageSize> pageSizes = [];
  late TPdfController tPdfController;
  bool initialLoaded = false;

  void setPageSizes(List<PageSize> pageSizes, TPdfController tController) {
    tPdfController = tController;
    this.pageSizes = pageSizes;
    _state = ReaderState(pageOffsets: []);
  }

  void dispatch(StateEvent event) {
    // Scroll Event နှစ်ခုလုံးကို မိအောင်ဖမ်းမယ်
    if (event is MouseScrollChanged || event is MouseThumbScrollChanged) {
      _setScrollingTrue();
    }

    if (event is LayoutChanged) {
      _handleLayout(event);
    } else if (event is MouseScrollChanged) {
      _handleMouseScroll(event);
    } else if (event is MouseThumbScrollChanged) {
      _handleMouseThumbScroll(event);
    } else if (event is PdfScaleUpdated) {
      _handelScaleUpdate(event);
    } else if (event is ZoomChanged) {
      _handleZoomUpdate(event);
    } else if (event is JumpToPage) {
      _jumpToPage(event);
    }
  }

  void _jumpToPage(JumpToPage event) {
    if (_state.lastConstraints == null || pageSizes.isEmpty) return;

    final targetPageIndex = event.page - 1;
    final double newZoom = event.zoom ?? _state.zoomFactor;

    // ၁။ 🌟 အရေးကြီးဆုံးအချက် - Zoom တန်ဖိုးအသစ်အတိုင်း စာမျက်နှာ Offsets အားလုံးကို အရင်ဆုံး ပြန်တွက်ရပါမယ်
    final updatedPageOffsets = ReaderLayoutEngine.calculatePageOffsets(
      pageSizeList: pageSizes, // သင့် State ထဲက မူလ Size List
      zoomFactor: newZoom,
    );

    if (updatedPageOffsets.isEmpty) return;

    // ၂။ အသစ်တွက်ချက်ထားတဲ့ Offsets ထဲကမှ Target Page ကို ရှာဖွေခြင်း
    final targetPage = updatedPageOffsets.firstWhere(
      (page) => page.pageIndex == targetPageIndex,
      orElse: () => updatedPageOffsets.first,
    );

    // ၃။ တွက်ပြီးသား startOffset အမှန်ကို ယူပြီး State ထဲမှာ တစ်ခါတည်း Update လုပ်မယ်
    _state = _state.copyWith(
      zoomFactor: newZoom,
      pageOffsets:
          updatedPageOffsets, // Offsets အသစ်ကိုပါ State ထဲ ထည့်ပေးရပါမယ်
      currentScrollOffset: targetPage
          .startOffset, // Zoom အသစ်နဲ့ ကိုက်ညီသော နေရာသို့ ကွက်တိခုန်ခြင်း
      currentScrollOffsetX: event.offsetX ?? _state.currentScrollOffsetX,
    );

    // ၄။ ပြီးမှ Visible List ကို ဆောက်ပြီး UI ထံ ပို့လွှတ်မယ်
    _buildVisiblePagesList();
  }

  void _handleZoomUpdate(ZoomChanged event) {
    if (event.zoom < state.minScale || event.zoom > state.maxScale) return;
    // နဂို Zoom အဟောင်းကို သိမ်းထားမယ်
    final double oldZoom = _state.zoomFactor;
    final double newZoom = event.zoom;

    // ၁။ Zoom Factor အသစ်အတိုင်း Page Offsets တွေကို အသစ်ပြန်တွက်မယ်
    final updatedPageOffsets = ReaderLayoutEngine.calculatePageOffsets(
      pageSizeList: pageSizes,
      zoomFactor: newZoom,
    );

    final double oldScrollOffset = _state.currentScrollOffset;
    final double focalY = _state.lastConstraints!.maxWidth / 2;

    double newScrollOffset =
        ((oldScrollOffset + focalY) * (newZoom / oldZoom)) - focalY;

    // Scroll Offset က အနှုတ်တန်ဖိုး ဖြစ်မသွားအောင် ထိန်းမယ်
    if (newScrollOffset < 0) newScrollOffset = 0;

    _state = _state.copyWith(
      zoomFactor: newZoom,
      pageOffsets: updatedPageOffsets,
      currentScrollOffset: newScrollOffset,
      currentScrollOffsetX: 0,
    );
    _buildVisiblePagesList();
  }

  void _handelScaleUpdate(PdfScaleUpdated event) {
    // ၁။ Zoom Factor အသစ်အတိုင်း Page Offsets တွေကို အသစ်ပြန်တွက်ရပါမယ်
    final updatedPageOffsets = ReaderLayoutEngine.calculatePageOffsets(
      pageSizeList: pageSizes, // သင့် State ထဲက နဂို Size List
      zoomFactor: event.zoom,
    );

    // ၂။ State ထဲမှာ အကုန်လုံးကို တစ်ခါတည်း Update လုပ်မယ်
    _state = _state.copyWith(
      zoomFactor: event.zoom,
      pageOffsets:
          updatedPageOffsets, // <--- အသစ်တွက်ထားတဲ့ offset တွေကို ထည့်ပေးလိုက်ပြီ
      currentScrollOffset: -event.offsetY, // Gesture ကလာတဲ့ ScaledOffsetY
      currentScrollOffsetX: -event.offsetX,
    );

    // ၃။ ပြီးမှ Visible List ကို ဆောက်မယ်
    _buildVisiblePagesList();
  }

  void setCurrentScrollDirectChange(double scrollY) {
    _state = _state.copyWith(currentScrollOffset: scrollY);
    _controller.add(_state);
  }

  void _handleMouseThumbScroll(MouseThumbScrollChanged event) {
    double newScroll = event.scrollY;
    // လက်ရှိ ရှိပြီးသား pageOffsets မြေပုံပေါ်မူတည်ပြီး visible pages ကို စစ်ထုတ်သည်
    if (state.lastConstraints != null) {
      newScroll = newScroll.clamp(
        0.0,
        state.totalContentHeight - state.lastConstraints!.maxHeight,
      );
    }
    _state = _state.copyWith(currentScrollOffset: newScroll);
    _buildVisiblePagesList();
  }

  void _handleMouseScroll(MouseScrollChanged event) {
    double newScroll = _state.currentScrollOffset + event.scrollDelta.dy;
    // လက်ရှိ ရှိပြီးသား pageOffsets မြေပုံပေါ်မူတည်ပြီး visible pages ကို စစ်ထုတ်သည်
    if (state.lastConstraints != null) {
      newScroll = newScroll.clamp(
        0.0,
        state.totalContentHeight - state.lastConstraints!.maxHeight,
      );
    }
    _state = _state.copyWith(currentScrollOffset: newScroll);
    _buildVisiblePagesList();
  }

  void _handleLayout(LayoutChanged event) {
    if (pageSizes.isEmpty) return;

    // (က) Pure Engine ထံမှ စာမျက်နှာမြေပုံ အသစ်ကို တွက်ထုတ်ခိုင်းသည်
    final newOffsets = ReaderLayoutEngine.calculatePageOffsets(
      pageSizeList: pageSizes, // Event ထဲကနေ မူရင်း PDF sizes ကို ယူမယ်
      zoomFactor: _state.zoomFactor,
    );

    double totalHeight = newOffsets.fold(0, (sum, item) => sum + item.height);

    // (ခ) Layout Data များကို State ထဲသို့ အရင် သိမ်းဆည်းလိုက်သည်
    _state = _state.copyWith(
      pageOffsets: newOffsets,
      totalContentHeight: totalHeight,
      lastConstraints: event.constraints,
    );

    _buildVisiblePagesList();
  }

  void _buildVisiblePagesList() {
    if (_state.lastConstraints == null) return;

    final visible = ReaderLayoutEngine.getVisiblePages(
      allPageOffsets: _state.pageOffsets,
      scrollOffset: state.currentScrollOffset,
      viewportHeight: _state.lastConstraints!.maxHeight,
      zoomFactor: _state.zoomFactor,
    );

    final viewportHeight = _state.lastConstraints!.maxHeight;
    final int currentPageIndex = ReaderLayoutEngine.getCurrentCenterPageIndex(
      allPageOffsets: _state.pageOffsets,
      scrollOffset: _state.currentScrollOffset,
      viewportHeight: viewportHeight,
    );

    final int newPageNumber = currentPageIndex + 1;

    // 🌟 ၁။ Page တကယ်ပြောင်းမှသာ Event လွှတ်မယ်
    if (tPdfController._currentPage != newPageNumber) {
      tPdfController._currentPage = newPageNumber;
      tPdfController._pdfController.add(PdfPageChanged(currentPageIndex));
    }

    // 🌟 ၂။ Zoom Factor တကယ်ပြောင်းမှသာ Event လွှတ်မယ် (အရေးကြီးဆုံးအချက်)
    if (tPdfController._currentZoom != state.zoomFactor) {
      tPdfController._currentZoom = state.zoomFactor;
      tPdfController._pdfController.add(PdfZoomChanged(state.zoomFactor));
    }

    // 🌟 ၃။ Offset X တကယ်ပြောင်းမှသာ update လုပ်မယ်
    if (tPdfController._currentOffsetX != state.currentScrollOffsetX) {
      tPdfController._currentOffsetX = state.currentScrollOffsetX;
    }

    // State ကို အပြီးသတ် Update လုပ်ပြီး Stream ထဲသို့ ပို့လွှတ် (emit) သည်
    _state = _state.copyWith(visiblePages: visible);
    _controller.add(_state);

    if (!initialLoaded) {
      initialLoaded = true;
      tPdfController._pdfLoadedStopWatch.stop();
      tPdfController._totalPage = state.pageOffsets.length;
      tPdfController._pdfController.add(
        PdfLoaded(tPdfController._pdfLoadedStopWatch.elapsed),
      );
    }
  }

  Timer? _scrollEndTimer;
  void _setScrollingTrue() {
    // Scroll စဆွဲပြီဆိုရင် အရင် timer ဟောင်းကို ဖျက်မယ်
    _scrollEndTimer?.cancel();

    // အကယ်၍ လက်ရှိ state က false ဖြစ်နေရင် true ပြောင်းပြီး stream ထဲ ထည့်ပေးမယ်
    if (!_state.isScrolling) {
      _state = _state.copyWith(isScrolling: true);
      _controller.add(_state);
    }

    // Scroll ဆွဲတာ ရပ်သွားပြီး 400ms ကြာရင် isScrolling ကို false ပြန်ပြောင်းခိုင်းမယ်
    _scrollEndTimer = Timer(const Duration(milliseconds: 400), () {
      _state = _state.copyWith(isScrolling: false);
      _controller.add(_state); // UI ကိုအလင်းပြဖို့ stream ထဲ ထည့်မယ်
    });
  }

  void dispose() {
    _scrollEndTimer?.cancel();
    _controller.close();
  }
}
