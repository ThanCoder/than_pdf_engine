// ignore_for_file: public_member_api_docs, sort_constructors_first
class PageOffset {
  const PageOffset({
    required this.pageIndex,
    required this.top,
    required this.bottom,
    required this.width,
    required this.height,
  });

  final int pageIndex;
  final double top;
  final double bottom;
  final double width;
  final double height;

  @override
  String toString() {
    return 'PageOffset(pageIndex: $pageIndex, top: $top, bottom: $bottom, width: $width, height: $height)';
  }
}
