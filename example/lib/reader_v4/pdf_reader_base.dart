// ignore_for_file: avoid_print

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:than_pdf_engine/than_pdf_engine.dart';
import 'package:than_pdf_engine_example/reader_v4/core/pdf_reader_events.dart';
import 'package:than_pdf_engine_example/reader_v4/core/pdf_state_controller.dart';
import 'package:than_pdf_engine_example/reader_v4/logic_mixins/viewer_scroll_animation_mixin.dart';
import 'package:than_pdf_engine_example/reader_v4/pdf_page_item.dart';

class PdfReaderBase extends StatefulWidget {
  final List<PageSize> pageSizeList;
  final PdfBackgroundWorker backgroundWorker;
  const PdfReaderBase({
    super.key,
    required this.pageSizeList,
    required this.backgroundWorker,
  });

  @override
  State<PdfReaderBase> createState() => _PdfReaderBaseState();
}

class _PdfReaderBaseState extends State<PdfReaderBase>
    with ViewerScrollAnimationMixin, SingleTickerProviderStateMixin {
  //**************Scroll Animation******* */
  @override
  double get getCurrentScollOffset =>
      stateController.state.currentScrollOffsetY;

  @override
  void setCurrentScrollOffset(double value) {
    stateController.dispatch(PdfScrollYSetDirect(value));
  }

  @override
  double get totalHeight => stateController.state.totalContentHeight;

  late PdfStateController stateController;

  @override
  void initState() {
    stateController = PdfStateController(widget.pageSizeList);
    super.initState();
    initViewerAnimation();
  }

  @override
  void dispose() {
    stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        stateController.dispatch(PdfLayoutChanged(constraints));
        return mobileScrollListener(constraints);
      },
    );
  }

  Widget desktopScrollListener(BoxConstraints constraints) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          stateController.dispatch(PdfScrollChanged(event.scrollDelta.dy));
        }
      },
      child: buildWidgetList(constraints),
    );
  }

  double _baseZoom = 0.0;
  bool mobileZooming = false;
  Widget mobileScrollListener(BoxConstraints constraints) {
    return GestureDetector(
      onScaleStart: (details) {
        // setState(() {
        mobileZooming = true;
        _baseZoom = stateController.state.zoomFactor;
        //   mobileZooming = true;
        // });
      },
      onScaleUpdate: (details) {
        // ၁။ လက် ၂ ချောင်း သုံးထားခြင်း ရှိ/မရှိ စစ်ဆေးတာ (pointer count က ၂ ခု သို့မဟုတ် scale တန်ဖိုး ပြောင်းလဲသွားရင်)
        if (details.scale != 1.0) {
          stateController.dispatch(
            PdfZoomChanged(
              baseZoom: _baseZoom,
              scale: details.scale,
              focalPoint:
                  details.focalPoint, // X ကော Y ကော ပါဝင်သော မူရင်း Offset
            ),
          );
        } else {
          stateController.dispatch(
            PdfScrollChanged(-details.focalPointDelta.dy * 1.4),
          );
        }
      },
      onScaleEnd: (details) {
        mobileZooming = false;
        final velocity = -details.velocity.pixelsPerSecond.dy;
        if (velocity.abs() > 0) {
          viewerAnimateScroll(velocity);
        }
      },
      child: desktopScrollListener(constraints),
    );
  }

  Widget buildWidgetList(BoxConstraints constraints) {
    return StreamBuilder(
      stream: stateController.stateStream.distinct(
        (previous, next) => previous.visiblePages == next.visiblePages,
      ),
      builder: (context, asyncSnapshot) {
        return Stack(
          children: [
            ...buildStackPositionedPageList(constraints),
            scrollStackPositionedWidget(constraints),
            Positioned(left: 0, child: _testRow(constraints)),
          ],
        );
      },
    );
  }

  Widget _testRow(BoxConstraints constraints) {
    print('zoom: ${stateController.state.zoomFactor}');
    print('OffsetX: ${stateController.state.currentScrollOffsetX}');
    final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
    return Container(
      color: Colors.black,
      child: Row(
        children: [
          IconButton(
            color: const Color.fromARGB(255, 114, 211, 188),
            onPressed: () => stateController.dispatch(PdfZoomOut(viewportSize)),
            icon: Icon(Icons.zoom_out),
          ),
          IconButton(
            color: Colors.tealAccent,
            onPressed: () => stateController.dispatch(PdfZoomIn(viewportSize)),
            icon: Icon(Icons.zoom_in),
          ),
          TextButton(
            onPressed: () {
              stateController.dispatch(
                PdfPageJump(
                  920,
                  offsetX: -21.877777777777908,
                  zoom: 0.8487660790910458,
                ),
              );
            },
            child: Text('Jump To 920'),
          ),
        ],
      ),
    );
  }

  Widget scrollStackPositionedWidget(BoxConstraints constraints) {
    double thumbWidth = 50;
    double thumbHeight = 50;
    final viewportHeight = constraints.maxHeight;
    final maxScrollExtent =
        (stateController.state.totalContentHeight - viewportHeight).clamp(
          0.0,
          double.infinity,
        );

    double scrollRatio = 0;
    if (maxScrollExtent > 0) {
      scrollRatio =
          stateController.state.currentScrollOffsetY / maxScrollExtent;
    }
    final thumbTopOffset = scrollRatio * (viewportHeight - thumbHeight);

    return Positioned(
      top: thumbTopOffset.isFinite ? thumbTopOffset : 0.0,
      right: 10,
      width: thumbWidth,
      height: thumbHeight,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (maxScrollExtent <= 0) return;
          double scrollDeltaY = details.delta.dy * 2;
          double newThumbTop = thumbTopOffset + scrollDeltaY;
          newThumbTop = newThumbTop.clamp(0.0, viewportHeight - thumbHeight);
          final topRatio = newThumbTop / (viewportHeight - thumbHeight);
          stateController.dispatch(
            PdfScrollYSetDirect(topRatio * maxScrollExtent),
          );
          // setState(() {
          //   currentScrollOffset = topRatio * maxScrollExtent;
          // });
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
      ),
    );
  }

  List<Widget> buildStackPositionedPageList(BoxConstraints constraints) {
    final list = <Widget>[];
    // final showPageIndex = <int>[];
    for (var page in stateController.state.visiblePages) {
      // print('page: ${page.pageIndex}');
      // showPageIndex.add(page.pageIndex);

      final leftOffset =
          ((constraints.maxWidth - page.width) / 2) -
          stateController.state.currentScrollOffsetX;
      final topOffset =
          page.startOffset - stateController.state.currentScrollOffsetY;
      list.add(
        Positioned(
          key: ValueKey('pdf_page_${page.pageIndex}'),
          left: leftOffset,
          top: topOffset,
          height: page.height,
          width: page.width,
          child: PdfPageItem(
            pageOffset: page,
            backgroundWorker: widget.backgroundWorker,
            mobileZooming: mobileZooming,
          ),
        ),
      );
    }
    // print('show Page index: $showPageIndex');
    print('showPage: ${list.length}');
    return list;
  }

  // void applyZoom(double zoom) {
  //   zoom = zoom.clamp(zoomMinScale, zoomMaxScale);
  //   zoomFactor = zoom;
  //   // print('applay: $zoom');
  //   setState(() {});
  // }
}
