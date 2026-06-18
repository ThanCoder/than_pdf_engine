// ignore_for_file: public_member_api_docs, sort_constructors_first
sealed class PdfReaderEvent {}

class PdfScreenSizeChanged extends PdfReaderEvent {
  final double zoom;
  final double maxWidth;
  PdfScreenSizeChanged(this.zoom, this.maxWidth);
}

class PdfViwerOnAttached extends PdfReaderEvent {
  final int totalPage;
  PdfViwerOnAttached({required this.totalPage});
}

class PdfOnLoaded extends PdfReaderEvent {
  final int page;
  final int totalPage;
  final Duration loadedElapsedTime;
  PdfOnLoaded({
    required this.page,
    required this.totalPage,
    required this.loadedElapsedTime,
  });
}

class PdfPageChanged extends PdfReaderEvent {
  final int page;
  PdfPageChanged(this.page);
}

class PdfZoomChanged extends PdfReaderEvent {
  final double zoom;
  PdfZoomChanged(this.zoom);
}

class PdfError extends PdfReaderEvent {
  final String error;
  PdfError(this.error);
}

class PdfCacheChanged extends PdfReaderEvent {
  final int length;
  final int size;
  PdfCacheChanged({required this.length, required this.size});
}

class PdfVisiablePageChanged extends PdfReaderEvent {
  final Map<int, bool> map;
  PdfVisiablePageChanged({required this.map});
}

class PdfScreenOffsetXChanged extends PdfReaderEvent {
  final double offsetX;
  PdfScreenOffsetXChanged(this.offsetX);
}
