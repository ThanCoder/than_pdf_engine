import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class RgbaBytesViewer extends StatefulWidget {
  final Uint8List rgbaBytes;
  final double width; // UI Display Width (ဥပမာ ဖုန်း screen အပြည့်)
  final double height; // UI Display Height (အချိုးကျ တွက်ထားသော height)
  final int imageWidth; // 🎯 C++ က ထွက်လာတဲ့ Pixel Width အစစ်
  final int imageHeight; // 🎯 C++ က ထွက်လာတဲ့ Pixel Height အစစ်

  const RgbaBytesViewer({
    super.key,
    required this.rgbaBytes,
    required this.width,
    required this.height,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  State<RgbaBytesViewer> createState() => _RgbaBytesViewerState();
}

class _RgbaBytesViewerState extends State<RgbaBytesViewer> {
  ui.Image? _uiImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _decodeRgbaBytes();
  }

  @override
  void didUpdateWidget(covariant RgbaBytesViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 💡 Layout Size (width/height) ပြောင်းရုံနဲ့ decode ထပ်မလုပ်တော့ဘူး (ဥပမာ- Zoom ဆွဲရင် သက်သာအောင်)
    // ရုပ်ထွက် Byte array သို့မဟုတ် C++ Resolution အစစ် ပြောင်းမှသာ ပုံအသစ် ပြန်ဆွဲမယ်
    if (oldWidget.rgbaBytes != widget.rgbaBytes ||
        oldWidget.imageWidth != widget.imageWidth ||
        oldWidget.imageHeight != widget.imageHeight) {
      _decodeRgbaBytes();
    }
  }

  Future<void> _decodeRgbaBytes() async {
    if (widget.rgbaBytes.isEmpty) {
      setState(() {
        _isLoading = false;
        _uiImage = null;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🎯 [အဓိက ပြင်ဆင်ချက်] Widget layout size မဟုတ်ဘဲ C++ ရဲ့ Resolution အစစ်ကို ကျွေးရပါမယ်
      ui.decodeImageFromPixels(
        widget.rgbaBytes,
        widget.imageWidth, // 👈 ဥပမာ 1080
        widget.imageHeight, // 👈 ဥပမာ 1920
        ui.PixelFormat.rgba8888,
        (ui.Image image) {
          if (mounted) {
            setState(() {
              _uiImage = image;
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      debugPrint("RGBA Bytes Decode Error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_uiImage == null) {
      return const Center(child: Text('Render Failed'));
    }

    // 💡 GPU ပေါ်က Raw Image ကိုမှ လက်ရှိ Layout အရွယ်အစားအတိုင်း အချိုးကျ ချုံ့/ချဲ့ ပြသပေးမယ်
    return RawImage(
      image: _uiImage,
      width: widget.width,
      height: widget.height,
      fit: BoxFit.contain,
    );
  }

  @override
  void dispose() {
    _uiImage?.dispose();
    super.dispose();
  }
}
