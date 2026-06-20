// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';

sealed class PdfReaderEvent {}

class PdfLayoutChanged extends PdfReaderEvent {
  final BoxConstraints constraints;
  PdfLayoutChanged(this.constraints);
}

class PdfScrollChanged extends PdfReaderEvent {
  final double deltaY;
  PdfScrollChanged(this.deltaY);
}

class PdfScrollYSetDirect extends PdfReaderEvent {
  final double exactOffset;
  PdfScrollYSetDirect(this.exactOffset);
}

class PdfZoomIn extends PdfReaderEvent {
  final Size
  viewportSize; // 💡 မျက်နှာပြင်ရဲ့ အလယ်ဗဟိုကို ရှာဖို့ Screen Size လိုအပ်ပါတယ်
  PdfZoomIn(this.viewportSize);
}

class PdfZoomOut extends PdfReaderEvent {
  final Size viewportSize;
  PdfZoomOut(this.viewportSize);
}

class PdfScaleChanged extends PdfReaderEvent {
  final double zoom;
  final double offsetX;
  final double offsetY;
  PdfScaleChanged({
    required this.zoom,
    required this.offsetX,
    required this.offsetY,
  });
}

class PdfZoomChanged extends PdfReaderEvent {
  final double scale;
  final double baseZoom;
  final Offset focalPoint;

  PdfZoomChanged({
    required this.scale,
    required this.focalPoint,
    required this.baseZoom,
  });
}

class PdfPageJump extends PdfReaderEvent {
  final int pageIndex;
  final double? zoom;
  final double? offsetX;
  PdfPageJump(this.pageIndex, {this.offsetX, this.zoom});
}
