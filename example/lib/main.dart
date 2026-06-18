// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:than_pdf_engine/than_pdf_engine.dart';
import 'package:than_pdf_engine_example/rbga_image_viewer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PdfCore.initPdfLib();
  runApp(MaterialApp(home: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void dispose() {
    pdfCore.dispose();
    super.dispose();
  }

  List<PageSize> list = [];
  final pdfCore = PdfCore();
  bool isLoading = false;
  void init() async {
    setState(() {
      isLoading = false;
    });
    await pdfCore.open('/home/thancoder/Documents/test1.pdf');

    list = await pdfCore.getAllPageSizedList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widget),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          init();
        },
      ),
    );
  }

  Widget get _widget {
    if (list.isEmpty) {
      return Text('list empty');
    }
    // return CircularProgressIndicator.adaptive();
    return ListView.builder(
      itemCount: list.length,
      itemExtentBuilder: (index, dimensions) {
        final ps = list[index];
        return ps.height;
      },
      itemBuilder: (context, index) => _listItem(list[index]),
    );

    // return RgbaBytesViewer(rgbaBytes: rgbaBytes!, width: width, height: height);
  }

  Widget _listItem(PageSize ps) {
    return PageItem(core: pdfCore, ps: ps);
  }
}

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
    init();
    super.initState();
  }

  Uint8List? bytes;
  bool isLoading = false;
  void init() async {
    // ၁။ ဒေတာ ရှိပြီးသားဆိုရင် သို့မဟုတ် တွက်ချက်နေတုန်းဆိုရင် ဘာမှမလုပ်ဘဲ ပြန်လှည့်ပါ
    if (bytes != null || isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      // ၂။ Background Isolate ကနေ ဒေတာ လှမ်းတောင်းမယ်
      final res = await widget.core.getRgbaImgesZeroCopy(widget.ps.pageIndex);

      if (res == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      // 💡 ၃။ [အဓိကပြင်ဆင်ချက်] Transferable ထဲကနေ Uint8List ထုတ်ယူနည်း အမှန်
      final rawBuffer = res.materialize().asUint8List();
      // final uint8list = Uint8List.view(rawBuffer);

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
    print('call');
    return _widget;
  }

  Widget get _widget {
    if (bytes == null) {
      return Placeholder();
    }
    return RgbaBytesViewer(
      rgbaBytes: bytes!,
      width: widget.ps.width.toInt(),
      height: widget.ps.height.toInt(),
    );
  }
}
