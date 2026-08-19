// ignore_for_file: public_member_api_docs, sort_constructors_first
class ReaderState {}

class ScrollbarInfo {
  const ScrollbarInfo({required this.thumbTop, required this.thumbHeight});

  final double thumbTop;
  final double thumbHeight;

  ScrollbarInfo copyWith({double? thumbTop, double? thumbHeight}) {
    return ScrollbarInfo(
      thumbTop: thumbTop ?? this.thumbTop,
      thumbHeight: thumbHeight ?? this.thumbHeight,
    );
  }
}
