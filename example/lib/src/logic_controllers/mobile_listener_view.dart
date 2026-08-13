import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:than_pdf_engine_example/src/events/state_events.dart';
import 'package:than_pdf_engine_example/src/interfaces/i_pdf_platform_controller.dart';

class MobileListenerView extends IListenerView {
  // Gesture စတင်ချိန်က တန်ဖိုးဟောင်းတွေကို ယာယီမှတ်ထားဖို့
  double _startZoom = 1.0;
  double _startOffsetX = 0.0;
  double _startOffsetY = 0.0;
  Offset? _startFocalPoint;
  double _currentScrollY = 0.0;
  late AnimationController _animateScrollController;
  MobileListenerView({required super.pdfContext});

  @override
  Widget buildWithChild(
    BuildContext context,
    BoxConstraints constraints,
    Widget child,
  ) {
    return GestureDetector(
      onScaleStart: (details) {
        if (details.pointerCount == 1) {
          _animateScrollController.stop();
          _startFocalPoint = details.localFocalPoint;
          _currentScrollY = 0.0;
        }
        // လက် ၂ ချောင်း ထိလိုက်တဲ့အချိန် (Scale စလုပ်ချိန်)
        if (details.pointerCount == 2) {
          _startZoom =
              pdfContext.state.zoomFactor; // နဂို State ထဲက Zoom ကို ယူမယ်

          // အရေးကြီးဆုံးအချက်: Gesture ရဲ့ အနှုတ်ကမ္ဘာတန်ဖိုးအတိုင်း ပြန်ပြောင်းပြီး မှတ်ရပါမယ်
          _startOffsetX = -pdfContext.state.currentScrollOffsetX;
          _startOffsetY = -pdfContext
              .state
              .currentScrollOffset; // 0 မထားဘဲ လက်ရှိရောက်နေတဲ့နေရာကို မှတ်ခြင်း

          _startFocalPoint = details.localFocalPoint;
        }
      },
      onScaleUpdate: (details) {
        if (details.pointerCount == 1 && _startFocalPoint != null) {
          //scroll
          final dy = details.localFocalPoint.dy - _startFocalPoint!.dy;

          pdfContext.stateController.dispatch(
            MouseScrollChanged(Offset(0, -dy)),
          );
          _startFocalPoint = details.localFocalPoint;
        }
        // ၂။ လက်နှစ်ချောင်း (Scale/Zoom)
        if (details.pointerCount == 2 && _startFocalPoint != null) {
          // ၁။ Sensitivity ထိန်းညှိခြင်း
          const double sensitivity = 0.4;
          final double scaleMultiplier =
              1.0 + (details.scale - 1.0) * sensitivity;
          final double newZoom = (_startZoom * scaleMultiplier).clamp(0.3, 5.0);

          // ၂။ လက်ရှိ Frame ၏ စစ်မှန်သော Scale Ratio
          final double actualRatio = newZoom / _startZoom;

          // ၃။ လက်ရှိ လက်နှစ်ချောင်းကြား ဗဟိုမှတ် (Focal Point)
          final double focalX = details.localFocalPoint.dx;
          final double focalY = details.localFocalPoint.dy;

          // ၄။ ပြင်ဆင်ချက် - လက်နှစ်ချောင်းကြား ဗဟိုချက်ဆီကို တည့်တည့် Zoom ဝင်စေမည့် ပုံသေနည်းအမှန်
          // အစမှတ် Focal Point ကနေ လက်ရှိ Focal Point ဘယ်လောက်ရွေ့သွားလဲ (Delta) ကိုပါ ထည့်ပေါင်းပေးရပါမယ်
          final double deltaX = focalX - _startFocalPoint!.dx;
          final double deltaY = focalY - _startFocalPoint!.dy;

          // Focal Point ကို ဗဟိုပြုပြီး ကျုံ့/ချဲ့ လုပ်ခြင်း + လက်ဆွဲရွေ့လျားမှု (Delta) ကို ပေါင်းစပ်ခြင်း
          double newOffsetX =
              focalX - (focalX - _startOffsetX) * actualRatio + deltaX;
          double newOffsetY =
              focalY - (focalY - _startOffsetY) * actualRatio + deltaY;

          final offsetX = newOffsetX;
          final offsetY = newOffsetY;
          final zoom = newZoom;

          // ပြောင်းလဲမှုတန်ဖိုးများကို ပို့လွှတ်ခြင်း
          pdfContext.stateController.dispatch(
            PdfScaleUpdated(offsetX, offsetY, zoom),
          );
        }
      },
      onScaleEnd: (details) {
        _startFocalPoint = null;

        // လက်လွှတ်လိုက်တဲ့အချိန်က အရှိန်နှုန်း (Velocity)
        // FrictionSimulation မောင်းဖို့အတွက် Direction ပြောင်းပြန်ဖြစ်အောင် negative (-) ထည့်ပေးရပါတယ်
        final velocityY = -details.velocity.pixelsPerSecond.dy;

        if (velocityY.abs() > 100) {
          _currentScrollY = 0.0;
          _animateScrollController.value = 0.0;

          // Friction (ပွတ်တိုက်မှု) Simulation ဖန်တီးခြင်း
          final Simulation simulation = FrictionSimulation(
            0.15, // Drag coefficient (0.135 မှ 0.15 ဝန်းကျင်က iOS/Android အတိုင်း smooth ဖြစ်ပါတယ်)
            0.0, // Start position
            velocityY, // Start velocity
          );

          // Simulation စမောင်းပြီ
          _animateScrollController.animateWith(simulation);
        }
      },
      child: child,
    );
  }

  //*************Scroll Animation*********** */
  void animateScrollListener(TickerProvider provider) {
    _animateScrollController = AnimationController.unbounded(vsync: provider);
    _animateScrollController.addListener(() {
      if (!_animateScrollController.isAnimating) return;

      final double nextValue = _animateScrollController.value;

      // အမှားပြင်ဆင်ချက်- state.currentScrollOffset အစား _currentScrollY နဲ့ပဲ နှုတ်ရပါမယ်
      final double dy = nextValue - _currentScrollY;
      _currentScrollY = nextValue;

      // ရလာတဲ့ ပြောင်းလဲမှု Delta အတိုင်း dispatch လုပ်မယ်
      pdfContext.stateController.dispatch(MouseScrollChanged(Offset(0, dy)));
    });
  }

  void animateScrollControllerDispose() {
    _animateScrollController.dispose();
  }
}
