part of '../t_pdf_render_v3_base.dart';

mixin ScrollKeyboardHandlerMixin on State<TCustomPdfViewer> {
  void updateScrollPosition(double scrollDeltaY, double maxHeight);
  void goToPage(int pageIndex);
  Widget buildPageItems(BoxConstraints constraints);

  Widget pointerListener(BoxConstraints constraints) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          // print('scroll: ${event.scrollDelta.dy}');
          updateScrollPosition(
            event.scrollDelta.dy * widget.controller._mouseScrollSensitivity,
            constraints.maxHeight,
          );
        }
      },
      child: keyboardListener(constraints),
    );
  }

  // ************** Keyboard logic *****************
  final FocusNode _keyboardFocusNode = FocusNode();
  Widget keyboardListener(BoxConstraints constraints) {
    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // print('key: ${event.logicalKey}');
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            updateScrollPosition(-40.0, constraints.maxHeight);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            updateScrollPosition(40.0, constraints.maxHeight);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            goToPage(widget.controller._currentPage - 1);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            goToPage(widget.controller._currentPage + 1);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: buildPageItems(constraints),
    );
  }
}
