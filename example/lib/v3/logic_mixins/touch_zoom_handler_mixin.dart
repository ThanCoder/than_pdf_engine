part of '../t_pdf_render_v3_base.dart';

mixin TouchZoomHandlerMixin on State<TCustomPdfViewer> {
  double _baseZoom = 0.0;
  double get currentZoom;
  double get startScrollY;
  set startScrollY(double y);

  void viewerAnimateScrollStop();
  void applyZoom(double zoom);
  void buildLayout(BoxConstraints constraints);
  void viewerAnimateScroll(double velocity);
  Widget pointerListener(BoxConstraints constraints);

  Widget mobileGestureListener(BoxConstraints constraints) {
    return GestureDetector(
      onScaleStart: (details) {
        viewerAnimateScrollStop();
        _baseZoom = currentZoom;
      },
      onScaleUpdate: (details) {
        // print(details.pointerCount);
        if (details.pointerCount > 1) {
          // လက် ၂ ချောင်း zoom
          applyZoom(
            (_baseZoom * details.scale).clamp(
              widget.controller.minScale,
              widget.controller.maxScale,
            ),
          );
        } else {
          // mouse,touch -> position ပြောင်းလဲတာ
          final deltaX =
              details.focalPointDelta.dx *
              widget.controller._touchDragSensitivity;
          final deltaY =
              details.focalPointDelta.dy *
              widget.controller._touchDragSensitivity;
          // config ကိုစစ်
          bool offsetXlocked = widget.controller._isOffsetXLocked;
          // Smart lock ပွင့်နေရင်
          if (!widget.controller._isOffsetXAutoLockedEnable) {
            if (currentZoom > 1.0) {
              if (deltaX.abs() > (deltaY.abs() * 1.5)) {
                offsetXlocked = false;
              }
            }
          }
          // update val
          setState(() {
            startScrollY -= deltaY;
            if (!offsetXlocked) {
              widget.controller._currentReaderOffsetX -= deltaX;
            }
          });
          buildLayout(constraints);
        }
      },
      onScaleEnd: (details) {
        // - ထည့်ဖို့ အရေးကြီးတယ်နော်
        //touch scroll က ပြောင်းပြန်ကြီး
        final velocity = -details.velocity.pixelsPerSecond.dy;
        if (velocity.abs() > 0) {
          viewerAnimateScroll(velocity);
        }
      },
      child: pointerListener(constraints),
    );
  }
}
