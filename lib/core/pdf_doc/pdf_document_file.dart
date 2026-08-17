part of 'pdf_document.dart';

class PdfDocumentFile extends IPdfDocument with PdfDocExtraMixin {
  @override
  Pointer<fpdf_document_t__> _doc = nullptr;

  @override
  bool get isOpened => _isOpened;

  bool _isOpened = false;

  Pointer _path = nullptr;
  Pointer _password = nullptr;

  ///Usage
  ///
  ///```dart
  /// final openStatus = doc.open();
  ///
  /// openStatus.unwrapOr(false);
  ///
  ///  final openStatus = doc.open().fold(
  ///   ok: (value) => value,
  ///   err: (error) {
  ///     print('error: $error');
  ///     return false;
  ///   },
  // );
  ///```
  ///
  Result<bool, PdfiumStatus> open(String path, {String? password}) {
    FPDF_InitLibrary();

    _path = path.toNativeUtf8();
    if (password != null) {
      _password = password.toNativeUtf8();
    }

    _doc = FPDF_LoadDocument(_path.cast<Char>(), _password.cast<Char>());

    if (_doc == nullptr) {
      if (_path != nullptr) {
        malloc.free(_path);
        _path = nullptr;
      }

      if (_password != nullptr) {
        malloc.free(_password);
        _password = nullptr;
      }
      final status = PdfiumStatus.fromCode(FPDF_GetLastError());

      return Err(status);
    }
    _isOpened = true;
    return Ok(true);
  }

  /// Page Close
  ///
  /// free memory
  void close() {
    _isOpened = false;
    if (_path != nullptr) {
      malloc.free(_path);
      _path = nullptr;
    }
    if (_password != nullptr) {
      malloc.free(_password);
      _password = nullptr;
    }
    if (_doc != nullptr) {
      FPDF_CloseDocument(_doc);
      _doc = nullptr;
    }

    FPDF_DestroyLibrary();
  }
}
