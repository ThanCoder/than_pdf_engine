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
    animationController.value = stateController.currentOffset;

    final simulation = FrictionSimulation(
      0.135,
      stateController.currentOffset,
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
    stateController.stream.whereType<ReaderUILoaded>().listen((event) {
      stateController.setZoom(stateController.fitWidthZoom);
    });
    super.initState();
    onReaderInit();
  }

  @override
  void dispose() {
    worker.close();
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

  Widget get _viewer {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragEnd: (details) {
        final velocity = -details.velocity.pixelsPerSecond.dy;
        _fling(velocity);
      },

      onVerticalDragUpdate: (details) {
        animationController.stop();
        stateController.scrollBy(-details.delta.dy);
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
      print(
        'visible: ${stateController.visiblePages.map((e) => e.pageIndex).toList()}',
      );
      print('visiable len: ${stateController.visiblePages.length}');
      print('Cache Count: ${stateController.imageCache.len}');
      print('Cache Size: ${stateController.imageCache.size.toFileSizeLabel()}');
      // print('offset page: ${stateController.visiblePages.first}');
      final list = <Widget>[];
      for (var p in stateController.visiblePages) {
        final top = p.top - stateController.currentOffset;

        final left = ((constraints.maxWidth - p.width) / 2);

        list.add(
          Positioned(
            key: ValueKey('item: ${p.pageIndex}'),
            top: top,
            left: left,
            width: p.width,
            height: p.height,
            child: StreamBuilder(
              stream: stateController.stream.whereType<ScrollbarDragEvent>(),
              builder: (context, asyncSnapshot) {
                if (stateController.scrollbarDragging) {
                  return Icon(Icons.image_not_supported_outlined, size: 300);
                }
                return ReaderItem(
                  offset: p,
                  stateController: stateController,
                  worker: worker,
                  imageCache: stateController.imageCache,
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
    return Positioned(
      top: 0,
      left: 0,
      child: Row(
        spacing: 8,
        children: [
          StreamBuilder(
            stream: stateController.stream.whereType<PageChanged>(),
            builder: (context, asyncSnapshot) {
              return Text(
                '${stateController.page}/${stateController.totalPage}',
              );
            },
          ),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.red,
            ),
            onPressed: () {
              stateController.setZoom(stateController.zoom - 0.1);
            },
            icon: Icon(Icons.zoom_out),
          ),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.red,
            ),
            onPressed: () {
              stateController.setZoom(stateController.zoom + 0.1);
            },
            icon: Icon(Icons.zoom_in),
          ),
        ],
      ),
    );
  }
}
