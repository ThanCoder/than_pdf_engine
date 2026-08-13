part of 't_pdf_reader_base.dart';

class TPdfController {
  final _userController = StreamController<UserEvent>.broadcast();
  final _pdfController = StreamController<PdfEvent>.broadcast();
  Stream<UserEvent> get _userStream => _userController.stream;
  Stream<PdfEvent> get pdfStream => _pdfController.stream;

  final _pdfLoadedStopWatch = Stopwatch();

  final Widget Function(BuildContext context)? progressWidget;

  ///defaultScrollbarNeon
  ///
  ///defaultScrollbarMinimal
  ///
  ///defaultScrollbar1
  ///
  final Widget Function(double thumbWidth, double thumbHeight)? scrollbarWidget;
  final Widget Function(int page)? pageFooterWidget;
  final KeyEventResult Function(FocusNode node, KeyEvent event)? onKeyEvent;
  final double keyboardScrollSpeed;
  final PdfWorkerRequestImageType requestRenderHighQualityImageType;
  TPdfController({
    this.progressWidget,
    this.scrollbarWidget,
    this.pageFooterWidget,
    this.onKeyEvent,
    this.keyboardScrollSpeed = 50.0,
    this.requestRenderHighQualityImageType = .png,
  });

  // state
  int _currentPage = 0;
  int _totalPage = 0;
  double _currentZoom = 1.0;
  double _currentOffsetX = 0;

  int get currentPage => _currentPage;
  int get totalPage => _totalPage;
  double get currentZoom => _currentZoom;
  double get currentOffsetX => _currentOffsetX;

  Stream<PdfLoaded> get onPdfLoaded =>
      _pdfController.stream.where((e) => e is PdfLoaded).cast<PdfLoaded>();
  Stream<PdfPageChanged> get onPageChanged => _pdfController.stream
      .where((e) => e is PdfPageChanged)
      .cast<PdfPageChanged>();
  Stream<PdfZoomChanged> get onZoomChanged => _pdfController.stream
      .where((e) => e is PdfZoomChanged)
      .cast<PdfZoomChanged>();

  void zoomIn() {
    _userController.add(UserRequestZoomIn());
  }

  void zoomOut() {
    _userController.add(UserRequestZoomOut());
  }

  void jumpToPage(int page, {double? offsetX, double? zoom}) {
    _userController.add(UserRequestJumpPage(page, offsetX, zoom));
  }

  //*************Scrollbar*******************/
  final _scrollbarShowHideNotifier = ValueNotifier(true);
  void setScrollbarEnable(bool enable) {
    _scrollbarShowHideNotifier.value = enable;
  }

  ValueNotifier<bool> get scrollbarNotifier => _scrollbarShowHideNotifier;

  bool get isEnableScrollbar => _scrollbarShowHideNotifier.value;
}
