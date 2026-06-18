part of 't_pdf_render_v3_base.dart';

typedef CustomScrollBar =
    TCustomScrollbarWidget Function(BuildContext context, int pageIndex);
typedef CustomLoader = Widget Function(BuildContext context);
typedef CustomError = Widget Function(BuildContext context, String error);
typedef CustomPdfPageFooterWidget =
    TCustomPageFooterWidget Function(BuildContext context, int pageIndex);

class TPdfControllerV3 extends ChangeNotifier {
  // Internal State (Reader ဘက်ကနေ လာပြီး အပ်ဒိတ်လုပ်မယ့် တန်ဖိုးများ)
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;
  double _minScale = 1.0;
  double _maxScale = 4.0;
  double _currentZoom = 1.0;
  bool _isOffsetXLocked;
  bool _isOffsetXAutoLockedEnable;
  double _currentReaderOffsetX;
  final double _loadCacheLength;
  final CustomScrollBar? _customScrollbar;
  final CustomError? _customError;
  final CustomLoader? _customLoader;
  final CustomPdfPageFooterWidget? _customPdfPageFooterWidget;
  final double _mouseScrollSensitivity;
  final double _touchDragSensitivity;
  bool _showScrollbar;

  TPdfControllerV3({
    this._customScrollbar,
    this._currentReaderOffsetX = 0.0,
    this._isOffsetXLocked = true,
    this._isOffsetXAutoLockedEnable = true,
    this._showScrollbar = false,
    this._mouseScrollSensitivity = 1.0,
    this._touchDragSensitivity = 1.0,
    this._customPdfPageFooterWidget,
    this._customLoader,
    this._customError,
    this._currentPage = 0,
    this._minScale = 0.3,
    this._maxScale = 4.0,
    this._currentZoom = 1.0,
    this._loadCacheLength = 10,
  });
  bool get isShowScrollbar => _showScrollbar;
  double get currentReaderOffsetX => _currentReaderOffsetX;
  bool get isOffsetXLocked => _isOffsetXLocked;
  bool get isOffsetXAutoLockedEnable => _isOffsetXAutoLockedEnable;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get isReady => _isReady;
  double get minScale => _minScale;
  double get maxScale => _maxScale;
  double get currentZoom => _currentZoom;
  double get loadCacheLength => _loadCacheLength;
  // stop wathc
  final _stopWatch = Stopwatch();

  // *****************Event ********************
  @protected
  final StreamController<UserEvent> _userEventStreamController =
      StreamController<UserEvent>.broadcast();
  final StreamController<PdfReaderEvent> _pdfReaderEventStreamController =
      StreamController<PdfReaderEvent>.broadcast();

  /// listen pdf reader
  Stream<UserEvent> get _userEvent => _userEventStreamController.stream;
  Stream<PdfReaderEvent> get pdfReaderEvent =>
      _pdfReaderEventStreamController.stream;

  void _attachReader({required int totalPage}) {
    _totalPages = totalPage;
    _isReady = true;
    notifyListeners();
    if (!_pdfReaderEventStreamController.isClosed) {
      _pdfReaderEventStreamController.add(
        PdfViwerOnAttached(totalPage: totalPage),
      );
      _pdfReaderEventStreamController.add(PdfPageChanged(1));
    }
  }

  void _detachReader() {
    _isReady = false;
    _userEventStreamController.close();
    _pdfReaderEventStreamController.close();
  }

  Stream<PdfOnLoaded> get onLoaded =>
      pdfReaderEvent.where((e) => e is PdfOnLoaded).cast<PdfOnLoaded>();

  Stream<PdfScreenSizeChanged> get onSizedChanged => pdfReaderEvent
      .where((e) => e is PdfScreenSizeChanged)
      .cast<PdfScreenSizeChanged>();
  Stream<PdfPageChanged> get onPageChanged =>
      pdfReaderEvent.where((e) => e is PdfPageChanged).cast<PdfPageChanged>();

  Stream<PdfZoomChanged> get onZoomChanged =>
      pdfReaderEvent.where((e) => e is PdfZoomChanged).cast<PdfZoomChanged>();

  void _notifyListeners() {
    notifyListeners();
  }

  void jumpToPage(int page) =>
      _userEventStreamController.add(UserJumpToPage(page));

  /// Set Offset X or Pdf Screen Left-Right
  void setOffsetX(double offsetX, double zoom) {
    _userEventStreamController.add(UserSetOffsetX(offsetX, zoom));
  }

  /// 1x မှ 4x အတွင်းပဲ ပေးမယ်
  void setZoom(double zoomLevel) {
    final clampedZoom = zoomLevel.clamp(minScale, maxScale);
    if (clampedZoom == _currentZoom) return;
    if (!_userEventStreamController.isClosed) {
      _userEventStreamController.add(UserZoom(clampedZoom));
    }
  }

  void setOffsetXLocked(bool locked) {
    _isOffsetXLocked = locked;
    notifyListeners();
  }

  void setShowScrollbar(bool enable) {
    _showScrollbar = enable;
    notifyListeners();
    _userEventStreamController.add(UserRequestToPdfViewerStateRefersh());
  }

  void setOffsetXAutoLockedEnable(bool enable) {
    _isOffsetXAutoLockedEnable = enable;
    notifyListeners();
  }

  void setMinScale(double scale) {
    _minScale = scale;
    notifyListeners();
  }

  void setMaxScale(double scale) {
    _maxScale = scale;
    notifyListeners();
  }
}
