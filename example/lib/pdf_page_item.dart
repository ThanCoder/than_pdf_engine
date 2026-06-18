import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:than_pdf_engine/core/pdf_background_worker.dart';
import 'package:than_pdf_engine/core/pdf_core.dart';
import 'package:than_pdf_engine/core/types.dart';

class PageItem extends StatefulWidget {
  final PdfCore core;
  final PageSize ps;
  const PageItem({super.key, required this.core, required this.ps});

  @override
  State<PageItem> createState() => _PageItemState();
}

class _PageItemState extends State<PageItem> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    bytes = null;
    super.dispose();
  }

  Uint8List? bytes;
  bool isLoading = false;
  double currentWidth = 0;
  double currentHeigth = 0;

  void renderImage(BoxConstraints constraints) async {
    // ၁။ ဒေတာ ရှိပြီးသားဆိုရင် သို့မဟုတ် တွက်ချက်နေတုန်းဆိုရင် ဘာမှမလုပ်ဘဲ ပြန်လှည့်ပါ
    if (bytes != null || isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      // ၂။ Background Isolate ကနေ ဒေတာ လှမ်းတောင်းမယ်
      // final res = await widget.core.getRgbaImgesZeroCopy(widget.ps.pageIndex);
      final res = await PdfBackgroundWorker.instance.requestPageImageJpgQuality(
        widget.ps.pageIndex,
        deviceWidth: constraints.maxWidth,
        zoomFactor: 1,
        quality: 20,
      );

      if (res == null) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        return;
      }

      // 💡 ၃။ [အဓိကပြင်ဆင်ချက်] Transferable ထဲကနေ Uint8List ထုတ်ယူနည်း အမှန်
      final rawBuffer = res.trans.materialize().asUint8List();

      if (mounted) {
        setState(() {
          bytes = rawBuffer;
          isLoading = false; // အောင်မြင်ရင် ပိတ်မယ်
        });
      }
    } catch (e) {
      print('error: $e');
      if (mounted) {
        setState(() {
          isLoading = false; // error တက်ရင်လည်း ပိတ်မယ်
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ၁။ PDF စာမျက်နှာရဲ့ မူရင်း Aspect Ratio ကို တွက်ချက်တယ်
    final double aspectRatio = widget.ps.width / widget.ps.height;

    return LayoutBuilder(
      builder: (context, constraints) {
       
        if (bytes == null && !isLoading) {
          Future.microtask(() => renderImage(constraints));
        }

        // 💡 အားလုံးကို AspectRatio Widget နဲ့ အုပ်လိုက်ခြင်းဖြင့် space အပိုတွေကို ဖြတ်ချပစ်မယ်
        return AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            color: Colors.blueGrey, // Background အရောင်
            child: _buildChild(constraints),
          ),
        );
      },
    );
  }

  // သီးသန့် ခွဲထုတ်လိုက်တဲ့ Loading / Image build logic
  Widget _buildChild(BoxConstraints constraints) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (bytes == null) return const Center(child: Text('Failed to load'));

    return Column(
      children: [
        Expanded(
          child: Image.memory(
            bytes!,
            width: constraints.maxWidth,
            fit: BoxFit
                .contain, // AspectRatio က block အကျယ်အဝန်းကို ထိန်းပေးထားလို့ fill သုံးလို့ရပါပြီ
            gaplessPlayback: true,
          ),
        ),
        Text('Page: ${widget.ps.pageIndex}'),
      ],
    );
  }
}
