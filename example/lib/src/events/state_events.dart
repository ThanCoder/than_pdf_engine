// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

sealed class StateEvent {}

class LayoutChanged extends StateEvent {
  BoxConstraints constraints;
  LayoutChanged(this.constraints);
}

class MouseScrollChanged extends StateEvent {
  final Offset scrollDelta;
  MouseScrollChanged(this.scrollDelta);
}

class MouseThumbScrollChanged extends StateEvent {
  final double scrollY;
  MouseThumbScrollChanged(this.scrollY);
}

class PdfScaleUpdated extends StateEvent {
  final double offsetX;
  final double offsetY;
  final double zoom;
  PdfScaleUpdated(this.offsetX, this.offsetY, this.zoom);
}

class ZoomChanged extends StateEvent {
  final double zoom;
  ZoomChanged(this.zoom);
}

class JumpToPage extends StateEvent {
  final int page;
  final double? offsetX;
  final double? zoom;
  JumpToPage(this.page, this.offsetX, this.zoom);
}
