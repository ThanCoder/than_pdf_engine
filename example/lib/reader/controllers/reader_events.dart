part of 'reader_state_controller.dart';

extension ReaderStateExt on Stream<ReaderEvent> {
  Stream<T> whereType<T extends ReaderEvent>() {
    return where((e) => e is T).cast<T>();
  }
}

sealed class ReaderEvent {
  const ReaderEvent();
}

class UpdateViewort extends ReaderEvent {}

class UpdateViewortHeight extends ReaderEvent {}

class UpdateViewortWidth extends ReaderEvent {}

class UpdateVisiblePages extends ReaderEvent {}

class UpdateOffset extends ReaderEvent {}

class ReaderLoaded extends ReaderEvent {}

class ReaderUILoaded extends ReaderEvent {}

class PageChanged extends ReaderEvent {
  final int page;
  const PageChanged(this.page);
}

class ZoomChanged extends ReaderEvent {
  final double zoom;
  const ZoomChanged(this.zoom);
}

class ScrollbarUiChanged extends ReaderEvent {}

class ScrollbarDragEvent extends ReaderEvent {
  final bool scrollbarDragging;
  const ScrollbarDragEvent(this.scrollbarDragging);
}
