part of '../t_pdf_render_v3_base.dart';

mixin ViewerScrollAnimationMixin on State<TCustomPdfViewer>
    implements TickerProvider {
  late AnimationController _scrollAnimationController;
  final _scrollPhysics = const ClampingScrollPhysics();

  double get totalHeight;
  double get startScrollY;
  set startScrollY(double value);
  void viewerAnimateScrollStop() {
    _scrollAnimationController.stop();
  }

  void initViewerAnimation() {
    _scrollAnimationController = AnimationController.unbounded(vsync: this);
    _scrollAnimationController.addListener(() {
      double value = _scrollAnimationController.value;

      // အောက်ဆုံး သို့မဟုတ် အပေါ်ဆုံး boundary ရောက်ရင် animation ကို ရပ်လိုက်ခြင်း
      if (value < 0) {
        value = 0;
        _scrollAnimationController.stop();
      } else if (value > totalHeight) {
        value = totalHeight;
        _scrollAnimationController.stop();
      }

      setState(() {
        startScrollY = value;
      });
    });
  }

  void viewerAnimateScroll(double velocity) {
    final simulation = _scrollPhysics.createBallisticSimulation(
      ScrollMetricsNotification(
        metrics: FixedScrollMetrics(
          minScrollExtent: 0,
          maxScrollExtent: totalHeight,
          pixels: startScrollY,
          viewportDimension: MediaQuery.of(context).size.height,
          axisDirection: AxisDirection.down,
          devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
        ),
        context: context,
      ).metrics,
      velocity,
    );
    if (simulation == null) return;
    _scrollAnimationController.value = startScrollY;
    _scrollAnimationController.animateWith(simulation);
  }
}
