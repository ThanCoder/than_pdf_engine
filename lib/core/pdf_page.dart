part of 'pdf_core.dart';

class PdfPage {
  final PdfCore _core;
  PdfPage(this._core);

  Pointer<Void> _pagePtr = nullptr;

  int _width = 0;
  int _height = 0;
  int _pageIndex = 0;

  int get width => _width;
  int get height => _height;
  int get pageIndex => _pageIndex;

  void open(int pageIndex) {
    _pageIndex = pageIndex;
    _pagePtr = pdf_page_create_from_page_index(_core._pdfCore, pageIndex);
    _width = pdf_page_getRenderWith(_pagePtr, 1);
    _height = pdf_page_getRenderHeight(_pagePtr, 1);
  }

  Future<Uint8List?> getRgbaImage() async {
    final bufferSizePtr = calloc<Int>();

    final rgbaPtr = pdf_page_renderToRGBA(_pagePtr, 1, bufferSizePtr);
    final rgbaBytes = rgbaPtr.asTypedList(bufferSizePtr.value);
    final dartBytes = Uint8List.fromList(rgbaBytes);
    pdf_page_free_render_data(rgbaPtr);

    calloc.free(bufferSizePtr);
    return dartBytes;
  }

  Future<TransferableTypedData?> getRgbaImageZeroCopyType() async {
    try {
      final bufferSizePtr = calloc<Int>();
      final rgbaPtr = pdf_page_renderToRGBA(_pagePtr, 1, bufferSizePtr);

      if (rgbaPtr == nullptr || bufferSizePtr.value <= 0) {
        calloc.free(bufferSizePtr);
        return null;
      }

      // 1. C++ pointer ကနေ Dart representation ယူမယ်
      final rawBytes = rgbaPtr.asTypedList(bufferSizePtr.value);

      // 2. Memory Block အသစ်ထဲ ကူးထည့်မယ် (မရှိမဖြစ် လိုအပ်ပါတယ်)
      final dartBytes = Uint8List.fromList(rawBytes);

      // 3. Transferable Object အဖြစ် ပြောင်းမယ်
      final trans = TransferableTypedData.fromList([dartBytes]);

      // 4. C++ memory ကို ချက်ချင်း free မယ်
      // pdf_page_free_rendepr_data(rgbaPtr);
      // calloc.free(bufferSizePtr);

      return trans;
    } catch (e) {
      print(e);
      return null;
    }
  }

  void dispose() {
    // pdf_page_destroy(_pagePtr);
  }
}
