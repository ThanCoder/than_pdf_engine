part of 'pdf_document.dart';

mixin PdfDocExtraMixin on IPdfDocument {
  /// Usage
  ///
  /// ```dart
  /// for (var page in doc.allPages.unwrapOr([])) {
  ///   print('page: $page');
  /// }
  /// ```
  Result<List<PageSize>, String> get allPages {
    final list = <PageSize>[];
    for (var i = 0; i < pageCount; i++) {
      final p = FPDF_LoadPage(_doc, i);
      if (p == nullptr) continue;

      list.add(
        .new(
          page: i,
          width: FPDF_GetPageWidthF(p),
          height: FPDF_GetPageHeightF(p),
        ),
      );

      // free
      FPDF_ClosePage(p);
    }
    return Ok(list);
  }

  /// Function: FPDF_GetPageCount
  /// Get total number of pages in the document.
  /// Parameters:
  /// document    -   Handle to document. Returned by FPDF_LoadDocument.
  /// Return value:
  /// Total number of pages in the document.
  int get pageCount {
    return FPDF_GetPageCount(_doc);
  }
}
