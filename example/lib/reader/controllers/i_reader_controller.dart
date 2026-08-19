part of 'reader_state_controller.dart';

sealed class IReaderController {
  double get currentOffset;
  List<PageOffset> get visiblePages;
  List<PageSize> get pages;
  List<PageOffset> get getpageOffsets;
  double get totalOffset;
  double get recentViewportHeight;
  double get recentViewportWidth;
  bool get scrollbarDragging;
  double get zoom;
  double get maxZoom;
  double get minZoom;
  int get totalPage;
  int get page;
  ScrollbarInfo? get scrollbarInfo;
  double get scrollbarThumbHeight;
  double get scrollbarHeight;
  double get currentOffsetX;
  // Sensitivity Factor (0.1 = အလွန်နှေး, 0.3 = ငြိမ့်ငြိမ့်လေး, 1.0 = မူလအတိုင်း မြန်)
  double get zoomSensitivity;

  PageImageCache get imageCache;
}
