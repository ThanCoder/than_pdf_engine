// ignore_for_file: public_member_api_docs, sort_constructors_first
class PageOffset {
  final int pageIndex;
  final double startOffset;
  final double endOffset;
  final double width;
  final double height;
  PageOffset({
    required this.pageIndex,
    required this.startOffset,
    required this.endOffset,
    required this.width,
    required this.height,
  });

  PageOffset copyWith({
    int? pageIndex,
    double? startOffset,
    double? endOffset,
    double? width,
    double? height,
  }) {
    return PageOffset(
      pageIndex: pageIndex ?? this.pageIndex,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  String toString() {
    return 'PageOffset(pageIndex: $pageIndex, startOffset: $startOffset, endOffset: $endOffset, width: $width, height: $height)';
  }
}
