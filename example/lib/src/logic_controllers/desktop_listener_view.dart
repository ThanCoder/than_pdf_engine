// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:than_pdf_engine_example/src/events/state_events.dart';

import 'package:than_pdf_engine_example/src/interfaces/i_pdf_platform_controller.dart';

class DesktopListenerView extends IListenerView {
  final FocusNode pageFocusNode;
  DesktopListenerView({required super.pdfContext, required this.pageFocusNode});

  @override
  Widget buildWithChild(
    BuildContext context,
    BoxConstraints constraints,
    Widget child,
  ) {
    // final double scrollSpeed = 50.0;
    final double scrollSpeed = pdfContext.tPdfController.keyboardScrollSpeed;

    return Focus(
      autofocus: true,
      focusNode: pageFocusNode,
      onKeyEvent: (node, event) {
        // controller key event
        if (pdfContext.tPdfController.onKeyEvent != null) {
          final result = pdfContext.tPdfController.onKeyEvent!(node, event);
          if (result == .handled) return result;
        }
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            pdfContext.stateController.dispatch(
              MouseScrollChanged(Offset(0, -scrollSpeed)),
            );
            // 💡 Event ကို ငါတို့ ကိုင်တွယ်ပြီးပြီမလို့ တခြား widget တွေဆီ စီးဆင်းမသွားအောင် ဖြတ်ပစ်လိုက်ခြင်း
            return KeyEventResult.handled;
          }

          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            pdfContext.stateController.dispatch(
              MouseScrollChanged(Offset(0, scrollSpeed)),
            );
            // 💡 default behavior (icon select လုပ်ခြင်း) ကို တားဆီးဖို့ handled ပြန်ပေးရပါမယ်
            return KeyEventResult.handled;
          }
        }
        return .ignored;
      },
      child: Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            pdfContext.stateController.dispatch(
              MouseScrollChanged(event.scrollDelta),
            );
          }
        },
        child: child,
      ),
    );
  }
}
