part of '../t_pdf_reader_base.dart';

class TReader extends StatefulWidget {
  final List<PageSize> pageSizes;
  final PdfBackgroundWorker pdfWorker;
  final TPdfController controller;
  const TReader({
    super.key,
    required this.pageSizes,
    required this.pdfWorker,
    required this.controller,
  });

  @override
  State<TReader> createState() => _TReaderState();
}

class _TReaderState extends State<TReader> with SingleTickerProviderStateMixin {
  final stateController = ReaderStateController();

  ReaderState get state => stateController.state;

  late final IPdfPlatformController pdfPlatformController;
  late final IPdfContext pdfContext;

  @override
  void initState() {
    stateController.setPageSizes(widget.pageSizes, widget.controller);
    super.initState();
    pdfContext = PdfContext(
      pdfWorker: widget.pdfWorker,
      stateController: stateController,
      tPdfController: widget.controller,
    );
    pdfPlatformController = PdfPlatformController(context: pdfContext);
    pdfPlatformController.init();
    (pdfPlatformController.mobileListenerView as MobileListenerView)
        .animateScrollListener(this);
    init();
  }

  void init() {
    widget.controller._userStream.listen((event) {
      if (event is UserRequestZoomIn) {
        stateController.dispatch(ZoomChanged(state.zoomFactor + 0.1));
      } else if (event is UserRequestZoomOut) {
        stateController.dispatch(ZoomChanged(state.zoomFactor - 0.1));
      } else if (event is UserRequestJumpPage) {
        stateController.dispatch(
          JumpToPage(event.page, event.offsetX, event.zoom),
        );
      }
    });
  }

  @override
  void dispose() {
    pdfPlatformController.dispose();
    (pdfPlatformController.mobileListenerView as MobileListenerView)
        .animateScrollControllerDispose();
    stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.controller.onZoomChanged,
      builder: (context, asyncSnapshot) {
        return LayoutBuilder(
          builder: (context, constraints) {
            stateController.dispatch(LayoutChanged(constraints));
            // return desktopListener(constraints);
            return pdfPlatformController.desktopListenerView.buildWithChild(
              context,
              constraints,
              pdfPlatformController.mobileListenerView.buildWithChild(
                context,
                constraints,
                listWidget(constraints),
              ),
            );
          },
        );
      },
    );
  }

  Widget listWidget(BoxConstraints constraints) {
    return StreamBuilder(
      stream: stateController.stateStream.distinct(
        (prev, next) => prev.visiblePages == next.visiblePages,
      ),
      builder: (context, asyncSnapshot) {
        return Stack(
          children: [
            Stack(children: pageListItem(constraints)),
            pdfPlatformController.scrollbarView.build(context, constraints),
          ],
        );
      },
    );
  }

  List<Widget> pageListItem(BoxConstraints constraints) {
    final list = <Widget>[];
    // print(state.visiblePages);
    // print('pages: ${state.visiblePages.map((e) => e.pageIndex).join(',')}');
    for (var page in state.visiblePages) {
      final topPos = page.startOffset - state.currentScrollOffset;

      ///offset x
      double leftPos =
          ((constraints.maxWidth - page.width) / 2) -
          state.currentScrollOffsetX;
      list.add(
        Positioned(
          key: ValueKey('page_index_${page.pageIndex}'),
          top: topPos,
          left: leftPos,
          width: page.width,
          height: page.height,
          child: PageListItem(
            page: page,
            pdfWorker: widget.pdfWorker,
            controller: widget.controller,
            readerStateController: stateController,
          ),
        ),
      );
    }
    return list;
  }
}
