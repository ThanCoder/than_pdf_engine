part of '../pdf_document.dart';

sealed class IPdfPage {
  Pointer<fpdf_page_t__> get _page;
  bool get isLoaded;
}

class PdfPage extends IPdfPage with PdfPageImageMixin {
  final IPdfDocument _document;

  PdfPage(this._document);

  @override
  Pointer<fpdf_page_t__> _page = nullptr;

  bool _isLoaded = false;

  @override
  bool get isLoaded => _isLoaded;

  /// if `failed` -> it will call auto close
  ///
  /// pageIndex -> start `0`
  ///
  /// Usage
  ///```dart
  /// final page = PdfPage(doc);
  /// final pageResult = page.loadPage(0);
  /// if (pageResult.isErr) {
  ///   print(pageResult.unwrapError());
  ///   page.close();
  ///   return;
  /// }
  ///```
  ///
  Result<bool, String> loadPage(int pageIndex) {
    _page = bindings.FPDF_LoadPage(_document._doc, pageIndex);

    if (_page == nullptr) {
      return Err('Failed to load page $pageIndex:');
    }
    _isLoaded = true;
    return Ok(true);
  }

  /// Free Memory
  ///
  ///unction: FPDF_ClosePage Close a loaded PDF page.
  ///Parameters: page - Handle to the loaded page. Return value: None.
  void close() {
    if (_page != nullptr) {
      bindings.FPDF_ClosePage(_page);
      _page = nullptr;
    }
    _isLoaded = false;
  }
}
