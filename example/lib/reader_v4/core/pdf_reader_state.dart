// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';

class PdfReaderState {
  final List<PageOffset> pageOffsets;
  final List<PageOffset> visiblePages;
  final double currentScrollOffsetY;
  final double currentScrollOffsetX;
  final double totalContentHeight;
  final double zoomFactor;
  final double zoomMinScale;
  final double zoomMaxScale;
  final BoxConstraints? lastConstraints;
  PdfReaderState({
    this.lastConstraints,
    required this.pageOffsets,
    this.visiblePages = const [],
    this.currentScrollOffsetY = 0.0,
    this.currentScrollOffsetX = 0.0,
    this.totalContentHeight = 0.0,
    this.zoomFactor = 0.8,
    this.zoomMinScale = 0.2,
    this.zoomMaxScale = 5,
  });

  PdfReaderState copyWith({
    List<PageOffset>? pageOffsets,
    List<PageOffset>? visiblePages,
    double? currentScrollOffsetY,
    double? currentScrollOffsetX,
    double? totalContentHeight,
    double? zoomFactor,
    double? zoomMinScale,
    double? zoomMaxScale,
    BoxConstraints? lastConstraints,
  }) {
    return PdfReaderState(
      pageOffsets: pageOffsets ?? this.pageOffsets,
      visiblePages: visiblePages ?? this.visiblePages,
      currentScrollOffsetY: currentScrollOffsetY ?? this.currentScrollOffsetY,
      currentScrollOffsetX: currentScrollOffsetX ?? this.currentScrollOffsetX,
      totalContentHeight: totalContentHeight ?? this.totalContentHeight,
      zoomFactor: zoomFactor ?? this.zoomFactor,
      zoomMinScale: zoomMinScale ?? this.zoomMinScale,
      zoomMaxScale: zoomMaxScale ?? this.zoomMaxScale,
      lastConstraints: lastConstraints ?? this.lastConstraints,
    );
  }
}

class PageOffset {
  final double startOffset;
  final double endOffset;
  final int pageIndex;
  final double width;
  final double height;
  PageOffset({
    required this.startOffset,
    required this.endOffset,
    required this.pageIndex,
    required this.width,
    required this.height,
  });
}

class PageScale {
  final double offsetX;
  final double offsetY;
  final int pageIndex;
  const PageScale({this.offsetX = 0, this.offsetY = 0, this.pageIndex = 0});

  PageScale copyWith({
    double? offsetX,
    double? offsetY,
    double? zoomFactor,
    int? pageIndex,
  }) {
    return PageScale(
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      pageIndex: pageIndex ?? this.pageIndex,
    );
  }
}
