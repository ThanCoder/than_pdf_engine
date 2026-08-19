import 'dart:math';
import 'package:dart_core_extensions/dart_core_extensions.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:than_pdf_engine/core/high_level_api/reader/pdf_reader_worker.dart';
import 'package:than_pdf_engine_example/reader/controllers/reader_state_controller.dart';
import 'package:than_pdf_engine_example/reader/reader_item.dart';
import 'package:than_pdf_engine_example/reader/reader_scrollbar.dart';
import 'package:than_pdf_engine_example/reader/utils/page_offset_utils.dart';

part 'logic/reader_init_mixin.dart';

class PdfReader extends StatefulWidget {
  const PdfReader({super.key, required this.path, this.password});

  final String path;
  final String? password;

  @override
  State<PdfReader> createState() => _PdfReaderState();
}

class _PdfReaderState extends State<PdfReader>
    with ReaderInitMixin, SingleTickerProviderStateMixin {
  final worker = PdfReaderWorker();

  @override
  _PdfReaderState get state => this;

  @override
  final ReaderStateController stateController = ReaderStateController();

  void updateState() {
    if (!mounted) return;
    setState(() {});
  }

  void _fling(double velocity) {
    animationController.value = stateController.state.currentOffset;

    final simulation = FrictionSimulation(
      0.135,
      stateController.state.currentOffset,
      velocity,
    );

    animationController.animateWith(simulation);
  }

  late final AnimationController animationController;
  @override
  void initState() {
    animationController = AnimationController.unbounded(vsync: this);
    animationController.addListener(() {
      final offset = animationController.value;

      stateController.setOffset(offset);
    });
    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        stateController.addEvent(ScrollEnd());
      }
    });

    stateController.stream.whereType<ReaderUILoaded>().listen((event) {
      stateController.setZoom(stateController.fitWidthZoom);
    });

    super.initState();
    onReaderInit();
  }

  @override
  void dispose() {
    worker.close();
    animationController.dispose();
    super.dispose();
  }

  String? error;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator.adaptive());
    }
    if (error != null) {
      return Center(
        child: Text(error!, style: TextStyle(color: Colors.red)),
      );
    }
    return _viewer;
  }

  double _lastScale = 1.0;
  bool useMobileScale = false;
  Widget get _viewer {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: (details) {
        _lastScale = 1.0; // Pinch စတင်ချိန်မှာ 1.0 ပြန်စမယ်
        animationController.stop();
        useMobileScale = false;
        stateController.addEvent(MobileScaleStart());
      },
      onScaleUpdate: (details) {
        // ၁။ Scale (Zoom) လုပ်နေစဉ် - လက် ၂ ချောင်းထောက်ထားချိန်
        if (details.pointerCount > 1) {
          final double currentScale = details.scale;

          // Frame အသစ်နဲ့ အဟောင်းကြား ပြောင်းလဲသွားသည့် Delta Scale ကို တွက်ခြင်း
          final double deltaScale = currentScale / _lastScale;
          _lastScale =
              currentScale; // နောက် Frame အတွက် လက်ရှိ Scale ကို မှတ်ထားမယ်

          final double offsetY = details.focalPointDelta.dy;
          final double offsetX = details.focalPointDelta.dx;

          // Controller သို့ Delta Scale ကိုသာ ပို့ပေးပါမည်
          stateController.setMobileScale(deltaScale, offsetX, offsetY);
          useMobileScale = true;
          return;
        }

        // ၂။ Scroll (Drag) လုပ်နေစဉ် - လက် ၁ ချောင်းတည်း ထောက်ထားချိန်
        final double offsetY = details.focalPointDelta.dy;
        stateController.scrollBy(-offsetY);
      },
      onScaleEnd: (details) {
        stateController.addEvent(MobileScaleEnd());
        if (useMobileScale) {
          stateController.addEvent(MobileScaleChanged());
        }
        // Pinch Zoom မဟုတ်ဘဲ Single Drag အဆုံးမှာပဲ Fling Scroll အလုပ်လုပ်မည်
        final velocity = -details.velocity.pixelsPerSecond.dy;
        if (velocity.abs() > 50) {
          _fling(velocity);
        } else {
          // 🟢 Velocity မရှိဘဲ လက်လွှတ်လိုက်ရုံနဲ့ Scroll ရပ်သွားချိန်
          if (!useMobileScale) {
            stateController.addEvent(ScrollEnd());
          }
        }
      },
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            animationController.stop();
            final dy = event.scrollDelta.dy;
            stateController.scrollBy(dy);
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewportHeight = constraints.maxHeight;
            final viewportWidth = constraints.maxWidth;

            stateController.updateViewportHeight(viewportWidth, viewportHeight);
            stateController.setScrollbarHeight(viewportHeight);
            return Stack(
              children: [
                _body(constraints),
                _scrollbar(viewportHeight: viewportHeight),
                testHeaderWidget(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(BoxConstraints constraints) => StreamBuilder(
    stream: stateController.stream.whereType<UpdateVisiblePages>(),
    builder: (context, asyncSnapshot) {
      // print(
      //   'visible: ${stateController.visiblePages.map((e) => e.pageIndex).toList()}',
      // );
      // print('visiable len: ${stateController.visiblePages.length}');
      // print('Cache Count: ${stateController.imageCache.len}');
      // print('Cache Size: ${stateController.imageCache.size.toFileSizeLabel()}');
      // print('offset page: ${stateController.visiblePages.first}');
      final list = <Widget>[];
      for (var p in stateController.visiblePages) {
        final top = p.top - stateController.state.currentOffset;
        final defaultCenterLeft = (constraints.maxWidth - p.width) / 2;
        final left = defaultCenterLeft + stateController.state.currentOffsetX;

        list.add(
          Positioned(
            key: ValueKey('item: ${p.pageIndex}'),
            top: top,
            left: left,
            width: p.width,
            height: p.height,
            child: StreamBuilder(
              stream: stateController.stream.where(
                (e) => e is ScrollbarDragEvent || e is MobileScaleEnd,
              ),
              builder: (context, asyncSnapshot) {
                if (stateController.state.scrollbarDragging) {
                  final iconSize = min(p.width, p.height) * 0.4;
                  return Icon(
                    Icons.image_not_supported_outlined,
                    size: iconSize,
                  );
                }
                return ReaderItem(
                  offset: p,
                  stateController: stateController,
                  worker: worker,
                  imageCache: stateController.state.imageCache,
                );
              },
            ),
          ),
        );
      }
      return Stack(children: list);
    },
  );

  Widget _scrollbar({required double viewportHeight}) {
    return ReaderScrollbar(
      controller: stateController,
      animationController: animationController,
    );
  }

  Positioned testHeaderWidget() {
    final col = Theme.of(context).colorScheme;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: col.surfaceContainerHighest,
        child: SingleChildScrollView(
          scrollDirection: .horizontal,
          child: Row(
            spacing: 8,
            children: [
              StreamBuilder(
                stream: stateController.stream.whereType<PageChanged>(),
                builder: (context, asyncSnapshot) {
                  return TextButton(
                    onPressed: () {
                      stateController.jumpPageIndex(150);
                    },
                    child: Text(
                      '${stateController.state.page}/${stateController.state.totalPage}',
                    ),
                  );
                },
              ),

              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: col.surfaceContainer,
                  foregroundColor: col.onSurface,
                ),
                onPressed: () {
                  stateController.setZoom(stateController.state.zoom - 0.1);
                },
                icon: Icon(Icons.zoom_out),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: col.surfaceContainer,
                  foregroundColor: col.onSurface,
                ),
                onPressed: () {
                  stateController.setZoom(stateController.state.zoom + 0.1);
                },
                icon: Icon(Icons.zoom_in),
              ),
              StreamBuilder(
                stream: stateController.stream.whereType<ZoomChanged>(),
                builder: (context, asyncSnapshot) {
                  return Text(
                    'Zoom: ${stateController.state.zoom.toStringAsFixed(4)}',
                  );
                },
              ),
              StreamBuilder(
                stream: stateController.state.imageCache.stream,
                builder: (context, asyncSnapshot) {
                  return Row(
                    children: [
                      Text('C len: ${stateController.state.imageCache.len}'),
                      Text(
                        'C Size: ${stateController.state.imageCache.size.toFileSizeLabel()}',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
