// ignore_for_file: public_member_api_docs, sort_constructors_first
class PageSize {
  final int page;
  final double width;
  final double height;
  const PageSize({
    required this.page,
    required this.width,
    required this.height,
  });

  @override
  String toString() => 'PageSize(page: $page, width: $width, height: $height)';
}
