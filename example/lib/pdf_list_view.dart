import 'package:flutter/material.dart';
import 'package:than_pdf_engine/core/pdf_background_worker.dart';
import 'package:than_pdf_engine/core/pdf_core.dart';
import 'package:than_pdf_engine/core/types.dart';
import 'package:than_pdf_engine_example/pdf_page_item.dart';

class PdfListView extends StatefulWidget {
  final String path;
  const PdfListView({super.key, required this.path});

  @override
  State<PdfListView> createState() => _PdfListViewState();
}

class _PdfListViewState extends State<PdfListView> {
  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void dispose() {
    PdfBackgroundWorker.instance.dispose();
    pdfCore.dispose();
    scrollController.dispose();
    super.dispose();
  }

  List<PageSize> list = [];
  final pdfCore = PdfCore();
  bool isLoading = false;
  final scrollController = ScrollController();
  double _lastWidth = 0;
  double _zoomFactor = 1.0;

  void init() async {
    try {
      setState(() {
        isLoading = true;
      });
      await pdfCore.open(widget.path);

      list = await pdfCore.getAllPageSizedList();
      await PdfBackgroundWorker.instance.run(widget.path);
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('[PdfListView:Error] $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 💡 ၁။ Width အမှန်တကယ် ပြောင်းလဲသွားမှသာ အလုပ်လုပ်မယ်
          if (_lastWidth != constraints.maxWidth) {
            _lastWidth = constraints.maxWidth;

            // လက်ရှိ Layout မပြောင်းခင်က အခြေအနေတွေကို ချက်ချင်း သိမ်းထားမယ်
            if (scrollController.hasClients) {
              final currentOffset = scrollController.offset;
              final maxOffset = scrollController.position.maxScrollExtent;

              // Layout မပြောင်းခင် Scroll ရောက်နေတဲ့ ရာခိုင်နှုန်း (Ratio) ကို တွက်တယ်
              // တကယ်လို့ ထိပ်ဆုံးမှာဆိုရင် ၀ ပေါ့
              final double scrollRatio = maxOffset > 0
                  ? (currentOffset / maxOffset)
                  : 0;

              // Layout အသစ်ဆွဲပြီးသွားတဲ့ (Layout Change End) အချိန်မှာ ပြန်တွက်မယ်
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!scrollController.hasClients) return;

                // 💡 ၂။ Layout အသစ်ရဲ့ Max Offset အသစ်ကို ယူတယ်
                final newMaxOffset = scrollController.position.maxScrollExtent;

                // 💡 ၃။ မူရင်း ရာခိုင်နှုန်း (Ratio) အတိုင်း Offset အသစ်ကို ပြန်မြှောက်ပြီး ရှာတယ်
                final targetOffset = newMaxOffset * scrollRatio;

                // နေရာအသစ်ကို ကွက်တိ ရွှေ့ပေးလိုက်ပြီ 🎯
                scrollController.jumpTo(targetOffset);
                // print(
                //   'Layout changed: Position reset to $targetOffset based on ratio',
                // );
              });
            }
          }
          final double baseWidth = MediaQuery.of(context).size.width;
          final double zoomedWidth = baseWidth * _zoomFactor;
          return SingleChildScrollView(
            scrollDirection: Axis
                .horizontal, // 👈 ညာဘက်ကို ပိုထွက်သွားရင် Scroll ဆွဲခွင့်ပေးမယ်
            child: SizedBox(
              width:
                  zoomedWidth, // 👈 တွက်ထားတဲ့ Zoom Width အတိုင်း အသေထိန်းချုပ်မယ်
              child: Center(child: _widget), // 👈 မင်းရဲ့ PDF ListView ကောင်
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          setState(() {
            _zoomFactor += 0.1;
          });
        },
      ),
    );
  }

  Widget get _widget {
    if (isLoading) {
      return CircularProgressIndicator.adaptive();
    }
    if (list.isEmpty) {
      return Text('list empty');
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: list.length,
      itemExtentBuilder: (index, dimensions) {
        final ps = list[index];
        final double screenWidth = MediaQuery.of(context).size.width;

        // စာမျက်နှာရဲ့ မူရင်း Width က Screen Width ထက် ကြီးနေရင် ချုံ့မယ်၊ သေးရင် ချဲ့မယ်
        // ဒီ Scale ကို သုံးပြီး အမြင့်အမှန်ကို ရှာတာ ဖြစ်ပါတယ်
        final double scale = screenWidth / ps.width;
        final double actualHeight = ps.height * scale;

        return actualHeight;
      },
      itemBuilder: (context, index) => _listItem(list[index]),
    );

    // return RgbaBytesViewer(rgbaBytes: rgbaBytes!, width: width, height: height);
  }

  Widget _listItem(PageSize ps) {
    return PageItem(core: pdfCore, ps: ps);
  }
}
