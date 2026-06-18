import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class RgbaBytesViewer extends StatefulWidget {
  final Uint8List rgbaBytes; // 💡 Pointer အစား Uint8List ကို တိုက်ရိုက်လက်ခံမယ်
  final int width;
  final int height;

  const RgbaBytesViewer({
    super.key,
    required this.rgbaBytes,
    required this.width,
    required this.height,
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
    // Bytes array သို့မဟုတ် size ပြောင်းသွားရင် ပုံအသစ် ပြန်ဆွဲမယ်
    if (oldWidget.rgbaBytes != widget.rgbaBytes ||
        oldWidget.width != widget.width ||
        oldWidget.height != widget.height) {
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
      // Raw Bytes တွေကို Flutter GPU Texture (ui.Image) အဖြစ် ပြောင်းလဲခြင်း
      ui.decodeImageFromPixels(
        widget.rgbaBytes,
        widget.width,
        widget.height,
        ui.PixelFormat.rgba8888, // RGBA Standard
        // ui.PixelFormat.rgba8888,
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

    // Engine အဆင့် RawImage နဲ့ ဆွဲတာမလို့ Performance အကောင်းဆုံး ဖြစ်ပါတယ်
    return RawImage(
      image: _uiImage,
      width: widget.width.toDouble(),
      height: widget.height.toDouble(),
      fit: BoxFit.contain,
    );
  }

  @override
  void dispose() {
    _uiImage?.dispose(); // GPU Memory ရှင်းလင်းခြင်း
    super.dispose();
  }
}
