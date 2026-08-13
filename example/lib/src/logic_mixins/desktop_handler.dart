import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:than_pdf_engine_example/src/events/state_events.dart';
import 'package:than_pdf_engine_example/src/state/reader_state.dart';
import 'package:than_pdf_engine_example/src/t_pdf_reader_base.dart';

mixin DesktopHandler {
  BuildContext get context;
  ReaderState get state;
  ReaderStateController get stateController;
  Widget mobileHandler(BoxConstraints constraints);

  Widget desktopListener(BoxConstraints constraints) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          stateController.dispatch(MouseScrollChanged(event.scrollDelta));
        }
      },
      child: mobileHandler(constraints),
    );
  }
}
