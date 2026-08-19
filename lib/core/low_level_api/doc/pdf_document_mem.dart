part of '../pdf_document.dart';

class PdfDocumentMem extends IPdfDocument with PdfDocExtraMixin {
  @override
  Pointer<fpdf_document_t__> _doc = nullptr;

  @override
  bool get isOpened => _isOpened;

  bool _isOpened = false;

  Pointer<UnsignedChar>? _data;
  int _dataSize = 0;
  Pointer _password = nullptr;

  ///Usage
  ///
  ///```dart
  ///  final docResult = doc.open(bytes);
  ///   if (docResult.isErr) {
  ///     print(docResult.unwrapError());
  ///     return;
  ///   }
  ///```
  ///
  Result<bool, PdfiumStatus> open(Uint8List data, {String? password}) {
    bindings.FPDF_InitLibrary();
    // PDF data အတွက် native memory allocate
    _data = malloc<UnsignedChar>(data.length);
    _dataSize = data.length;

    // Dart memory → native memory
    _data!.cast<Uint8>().asTypedList(data.length).setAll(0, data);

    if (password != null) {
      _password = password.toNativeUtf8();
    }

    // _doc = FPDF_LoadDocument(_path.cast<Char>(), _password.cast<Char>());
    _doc = bindings.FPDF_LoadMemDocument(
      _data!.cast<Void>(),
      _dataSize,
      _password.cast<Char>(),
    );

    if (_doc == nullptr) {
      final status = PdfiumStatus.fromCode(bindings.FPDF_GetLastError());

      malloc.free(_data!);
      _data = nullptr;
      _dataSize = 0;

      if (_password != nullptr) {
        malloc.free(_password);
        _password = nullptr;
      }

      return Err(status);
    }
    _isOpened = true;
    return Ok(true);
  }

  /// Page Close
  ///
  /// free memory
  void close() {
    if (_doc != nullptr) {
      bindings.FPDF_CloseDocument(_doc);
      _doc = nullptr;
    }

    if (_data != nullptr) {
      malloc.free(_data!);
      _data = nullptr;
    }
    if (_password != nullptr) {
      malloc.free(_password);
      _password = nullptr;
    }
    _isOpened = false;

    bindings.FPDF_DestroyLibrary();
  }
}
