part of '../t_pdf_render_v3_base.dart';

mixin ViewerCacheMixin on State<TCustomPdfViewer> {
  //
  final Map<int, Uint8List?> _loadedPagesCache = {};
  Map<int, Uint8List?> get loadedPagesCache => _loadedPagesCache;

  Future<TransferableTypedData?> _renderPdfPage(
    int pageIndex, {
    required double deviceWidth,
    double zoomFactor = 1,
    int quality = 90,
  }) async {
    // return await widget.document.getPageImage(pageIndex);
    final res = await PdfBackgroundWorker.instance.requestPageImageJpgQuality(
      pageIndex,
      deviceWidth: deviceWidth,
      zoomFactor: zoomFactor,
      quality: quality,
    );
    if (res == null) return null;
    return res.trans;
  }

  /// request image cache
  Future<void> initPageIntoCache(
    int index, {
    required double deviceWidth,
    double zoomFactor = 1,
    int quality = 90,
  }) async {
    if (loadedPagesCache.containsKey(index)) return;

    loadedPagesCache[index] = null; // Loading ပြဖို့ null အရင်ထားမယ်

    final renderedData = await _renderPdfPage(
      index,
      deviceWidth: deviceWidth,
      zoomFactor: zoomFactor,
      quality: quality,
    );

    if (!loadedPagesCache.containsKey(index)) {
      if (renderedData != null) {
        renderedData.materialize();
      }
      return;
    }
    // data ရှိမှ ထည့်မယ်
    if (renderedData != null) {
      final totalSize = loadedPagesCache.values.fold(
        0,
        (prev, val) => prev + (val == null ? 0 : val.length),
      );
      widget.controller._pdfReaderEventStreamController.add(
        PdfCacheChanged(length: loadedPagesCache.length, size: totalSize),
      );
      if (!mounted) return;
      setState(() {
        loadedPagesCache[index] = renderedData.materialize().asUint8List();
      });
    }
  }

  // ****************** Maintain Cache ***********************
  void maintainCacheLimit(int pageIndex) {
    final startKeep = pageIndex - widget.controller.loadCacheLength;
    final endKeep = pageIndex + widget.controller.loadCacheLength;

    final cachesIndex = loadedPagesCache.keys.toList();

    for (var index in cachesIndex) {
      if (index < startKeep || index > endKeep) {
        if (loadedPagesCache.containsKey(index)) {
          loadedPagesCache.remove(index);
        }
      }
    }
  }
}
