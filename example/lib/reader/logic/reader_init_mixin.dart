// ignore_for_file: library_private_types_in_public_api

part of '../pdf_reader.dart';

mixin ReaderInitMixin {
  _PdfReaderState get state;
  ReaderStateController get stateController;

  void onReaderInit() async {
    try {
      state.isLoading = true;
      state.error = null;
      state.updateState();

      final openRes = await state.worker.open(state.widget.path);

      if (openRes.isErr) {
        state.error = openRes.unwrapError().message;
        state.isLoading = false;
        state.updateState();
        return;
      }

      final pagesRes = await state.worker.getAllPageSizes();
      if (pagesRes.isErr) {
        state.error = pagesRes.unwrapError();

        state.isLoading = false;
        state.updateState();
        return;
      }
      stateController.pages = pagesRes.unwrap();

      state.isLoading = false;
      state.updateState();
      calcualteOffset();
    } catch (e) {
      state.error = e.toString();
      state.isLoading = false;
      state.updateState();
    }
  }

  void calcualteOffset() {
    stateController.totalOffset = stateController.pages.fold(
      0,
      (prev, ele) => prev + ele.height,
    );
    stateController.pageOffsets = PageOffsetUtils.calculatePageOffsets(
      stateController.pages,
      zoom: stateController.zoom,
    );

    if (stateController.pages.isNotEmpty) {
      stateController.totalPage = stateController.pages.length - 1;
    }

    stateController.addEvent(ReaderLoaded());

    /// ui
    Future.delayed(Duration(seconds: 1)).then((value) {
      stateController.addEvent(ReaderUILoaded());
    });
  }
}
