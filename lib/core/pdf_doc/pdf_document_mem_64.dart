part of 'pdf_document.dart';

class PdfDocumentMem64 extends IPdfDocument with PdfDocExtraMixin {
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
  Result<bool, PdfiumStatus> open(Uint8List data, {String? password}) {
    FPDF_InitLibrary();
    // PDF data အတွက် native memory allocate
    _data = malloc<UnsignedChar>(data.length);
    _dataSize = data.length;

    // Dart memory → native memory
    _data!.cast<Uint8>().asTypedList(data.length).setAll(0, data);

    if (password != null) {
      _password = password.toNativeUtf8();
    }

    // _doc = FPDF_LoadDocument(_path.cast<Char>(), _password.cast<Char>());
    _doc = FPDF_LoadMemDocument64(
      _data!.cast<Void>(),
      _dataSize,
      _password.cast<Char>(),
    );

    if (_doc == nullptr) {
      final status = PdfiumStatus.fromCode(FPDF_GetLastError());

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
      FPDF_CloseDocument(_doc);
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

    FPDF_DestroyLibrary();
  }
}
