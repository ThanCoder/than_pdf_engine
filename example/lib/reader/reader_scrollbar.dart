import 'package:flutter/material.dart';
import 'package:than_pdf_engine_example/reader/controllers/reader_state_controller.dart';

class ReaderScrollbar extends StatelessWidget {
  const ReaderScrollbar({
    super.key,
    required this.controller,
    required this.animationController,
  });

  final ReaderStateController controller;
  final AnimationController animationController;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: controller.stream.whereType<ScrollbarUiChanged>(),
      builder: (context, snapshot) {
        final info = controller.scrollbarInfo;

        if (info == null) {
          return Positioned(child: SizedBox.shrink());
        }

        return Positioned(
          top: info.thumbTop,
          right: 2,
          width: 8,
          height: info.thumbHeight,
          child: GestureDetector(
            onVerticalDragStart: (_) {
              controller.scrollbarDragging = true;
              controller.addEvent(ScrollbarDragEvent(true));
              animationController.stop();
            },
            onVerticalDragEnd: (details) {
              controller.scrollbarDragging = false;
              controller.addEvent(ScrollbarDragEvent(false));
            },
            onVerticalDragUpdate: (details) {
              final contentHeight = controller.contentHeight;
              final viewportHeight = controller.recentViewportHeight;

              final maxOffset = contentHeight - viewportHeight;

              final thumbHeight =
                  viewportHeight * viewportHeight / contentHeight;

              final maxThumbOffset = viewportHeight - thumbHeight;

              final delta = details.delta.dy / maxThumbOffset * maxOffset;

              controller.scrollBy(delta);
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      },
    );
  }
}
