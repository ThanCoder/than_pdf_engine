import 'dart:math';

import 'package:dart_core_extensions/dart_core_extensions.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:than_pdf_engine/core/high_level_api/reader/pdf_reader_worker.dart';
import 'package:than_pdf_engine_example/reader/controllers/reader_state_controller.dart';
import 'package:than_pdf_engine_example/reader/reader_item.dart';
import 'package:than_pdf_engine_example/reader/utils/page_image_cache.dart';
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
    _scrollController.value = stateController.currentOffset;

    final simulation = FrictionSimulation(
      0.135,
      stateController.currentOffset,
      velocity,
    );

    _scrollController.animateWith(simulation);
  }

  late final AnimationController _scrollController;
  @override
  void initState() {
    _scrollController = AnimationController.unbounded(vsync: this);
    _scrollController.addListener(() {
      final offset = _scrollController.value;

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
        _scrollController.stop();
        stateController.scrollBy(-details.delta.dy);
      },
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            _scrollController.stop();

            final dy = event.scrollDelta.dy;
            stateController.scrollBy(dy);
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewportHeight = constraints.maxHeight;
            final viewportWidth = constraints.maxWidth;
            stateController.updateViewportHeight(viewportWidth, viewportHeight);
            return Stack(
              children: [
                _body(constraints),
                StreamBuilder(
                  stream: stateController.stream
                      .whereType<UpdateVisiblePages>(),
                  builder: (context, asyncSnapshot) {
                    return _scrollbar(viewportHeight: viewportHeight);
                  },
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.red,
                    ),
                    onPressed: () {
                      stateController.setZoom(stateController.zoom - 0.1);
                    },
                    icon: Icon(Icons.zoom_out),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 100,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.red,
                    ),
                    onPressed: () {
                      stateController.setZoom(stateController.zoom + 0.1);
                    },
                    icon: Icon(Icons.zoom_in),
                  ),
                ),
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
            top: top,
            left: left,
            width: p.width,
            height: p.height,
            child: StreamBuilder(
              stream: stateController.stream.whereType<ScrollbarDragEvent>(),
              builder: (context, asyncSnapshot) {
                return stateController.scrollbarDragging
                    ? Column(
                        children: [
                          Text('Page: ${p.pageIndex}'),
                          Expanded(
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              size: 300,
                            ),
                          ),
                        ],
                      )
                    : ReaderItem(
                        key: ValueKey(p.pageIndex),
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
    final contentHeight = stateController.contentHeight;
    final offset = stateController.currentOffset;

    if (contentHeight <= viewportHeight) {
      return const SizedBox.shrink();
    }

    final thumbHeight = max(
      40.0,
      viewportHeight * viewportHeight / contentHeight,
    );

    final maxOffset = contentHeight - viewportHeight;
    final maxThumbOffset = viewportHeight - thumbHeight;

    final thumbTop = (offset / maxOffset) * maxThumbOffset;

    return Positioned(
      top: thumbTop,
      right: 2,
      width: 8,
      height: thumbHeight,
      child: GestureDetector(
        onVerticalDragStart: (_) {
          stateController.scrollbarDragging = true;
          stateController.addEvent(ScrollbarDragEvent(true));
          _scrollController.stop();
        },
        onVerticalDragEnd: (details) {
          stateController.scrollbarDragging = false;
          stateController.addEvent(ScrollbarDragEvent(false));
        },
        onVerticalDragUpdate: (details) {
          final contentHeight = stateController.contentHeight;
          final viewportHeight = stateController.recentViewportHeight;

          final maxOffset = contentHeight - viewportHeight;

          final thumbHeight = viewportHeight * viewportHeight / contentHeight;

          final maxThumbOffset = viewportHeight - thumbHeight;

          final delta = details.delta.dy / maxThumbOffset * maxOffset;

          stateController.scrollBy(delta);
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
