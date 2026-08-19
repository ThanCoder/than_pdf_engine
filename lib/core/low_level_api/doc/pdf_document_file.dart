part of '../pdf_document.dart';

class PdfDocumentFile extends IPdfDocument with PdfDocExtraMixin {
  @override
  Pointer<fpdf_document_t__> _doc = nullptr;

  @override
  bool get isOpened => _isOpened;

  bool _isOpened = false;

  Pointer _path = nullptr;
  Pointer _password = nullptr;

  /// if `failed` -> it will call auto close
  ///
  ///Usage
  ///
  ///```dart
  ///  final docResult = doc.open(path);
  ///   if (docResult.isErr) {
  ///     print(docResult.unwrapError());
  ///     return;
  ///   }
  ///```
  ///
  Result<bool, PdfiumStatus> open(String path, {String? password}) {
    bindings.FPDF_InitLibrary();
    // final config = calloc<FPDF_LIBRARY_CONFIG_>();
    // config.ref.m_v8EmbedderSlot
    // FPDF_InitLibraryWithConfig(config)

    _path = path.toNativeUtf8();
    if (password != null) {
      _password = password.toNativeUtf8();
    }

    _doc = bindings.FPDF_LoadDocument(_path.cast<Char>(), _password.cast<Char>());

    if (_doc == nullptr) {
      if (_path != nullptr) {
        malloc.free(_path);
        _path = nullptr;
      }

      if (_password != nullptr) {
        malloc.free(_password);
        _password = nullptr;
      }
      final status = PdfiumStatus.fromCode(bindings.FPDF_GetLastError());

      return Err(status);
    }
    _isOpened = true;
    return Ok(true);
  }

  /// Page Close
  ///
  /// free memory
  void close({bool destroyPdfiumLib = false}) {
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
      bindings.FPDF_CloseDocument(_doc);
      _doc = nullptr;
    }
    if (destroyPdfiumLib) {
      bindings.FPDF_DestroyLibrary();
    }
  }
}
