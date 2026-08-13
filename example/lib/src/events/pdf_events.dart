sealed class PdfEvent {}

class PdfLoaded extends PdfEvent {
  final Duration elapsed;
  PdfLoaded(this.elapsed);
}

class PdfPageChanged extends PdfEvent {
  final int page;
  PdfPageChanged(this.page);
}
class PdfZoomChanged extends PdfEvent {
  final double zoom;
  PdfZoomChanged(this.zoom);
}
