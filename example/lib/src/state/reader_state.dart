// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'package:than_pdf_engine_example/src/reader/page_offset.dart';

class ReaderState {
  final double currentScrollOffset;
  final double currentScrollOffsetX;
  final double totalContentHeight;
  final double maxScale;
  final double minScale;
  final double zoomFactor;
  final BoxConstraints? lastConstraints;
  final List<PageOffset> pageOffsets;
  final List<PageOffset> visiblePages;
  final bool isScrolling;
  ReaderState({
    this.currentScrollOffset = 0,
    this.currentScrollOffsetX = 0,
    this.totalContentHeight = 0,
    this.minScale = 0.2,
    this.maxScale = 5,
    this.zoomFactor = 1,
    this.lastConstraints,
    required this.pageOffsets,
    this.visiblePages = const [],
    this.isScrolling = false,
  });

  ReaderState copyWith({
    double? currentScrollOffset,
    double? currentScrollOffsetX,
    double? totalContentHeight,
    double? maxScale,
    double? minScale,
    double? zoomFactor,
    BoxConstraints? lastConstraints,
    List<PageOffset>? pageOffsets,
    List<PageOffset>? visiblePages,
    bool? isScrolling,
  }) {
    return ReaderState(
      currentScrollOffset: currentScrollOffset ?? this.currentScrollOffset,
      currentScrollOffsetX: currentScrollOffsetX ?? this.currentScrollOffsetX,
      totalContentHeight: totalContentHeight ?? this.totalContentHeight,
      maxScale: maxScale ?? this.maxScale,
      minScale: minScale ?? this.minScale,
      zoomFactor: zoomFactor ?? this.zoomFactor,
      lastConstraints: lastConstraints ?? this.lastConstraints,
      pageOffsets: pageOffsets ?? this.pageOffsets,
      visiblePages: visiblePages ?? this.visiblePages,
      isScrolling: isScrolling ?? this.isScrolling,
    );
  }
}
