part of '../pdf_document.dart';

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
      final size = calloc<FS_SIZEF_>();

      final result = bindings.FPDF_GetPageSizeByIndexF(_doc, i, size);

      if (result == 0) {
        // error
        list.add(.new(page: i, width: 0, height: 0));
      } else {
        //success
        list.add(.new(page: i, width: size.ref.width, height: size.ref.height));
      }

      calloc.free(size);
    }
    return Ok(list);
  }

  /// Function: FPDF_GetPageCount
  /// Get total number of pages in the document.j
  /// Parameters:
  /// document    -   Handle to document. Returned by FPDF_LoadDocument.
  /// Return value:
  /// Total number of pages in the document.
  int get pageCount {
    return bindings.FPDF_GetPageCount(_doc);
  }
}
