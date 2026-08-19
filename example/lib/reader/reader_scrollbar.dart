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
        final info = controller.state.scrollbarInfo;

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
              controller.state.scrollbarDragging = true;
              controller.addEvent(ScrollbarDragEvent(true));
              animationController.stop();
            },
            onVerticalDragEnd: (details) {
              controller.state.scrollbarDragging = false;
              controller.addEvent(ScrollbarDragEvent(false));
            },
            onVerticalDragUpdate: (details) {
              final info = controller.state.scrollbarInfo;
              if (info == null) return;

              final contentHeight = controller.contentHeight;
              final viewportHeight = controller.state.recentViewportHeight;
              final scrollbarHeight =
                  controller.state.scrollbarHeight; // သို့မဟုတ် viewportHeight

              // Max offsets
              final maxOffset = contentHeight - viewportHeight;

              // 🟢 CORRECT: info.thumbHeight ကို တိုက်ရိုက်သုံးရပါမည်
              final maxThumbOffset = scrollbarHeight - info.thumbHeight;

              if (maxThumbOffset <= 0) return;

              // Real Drag Delta Ratio
              final delta = (details.delta.dy / maxThumbOffset) * maxOffset;

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
