// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';

enum RenderQuality { low, high }

class RenderTask {
  final int page;
  final RenderQuality quality;

  const RenderTask({required this.page, required this.quality});
}

class PdfImageQueue {
  PdfImageQueue(this.render);

  final Future<Uint8List> Function(int page, RenderQuality quality) render;

  final Set<int> _waiting = {};
  final Set<int> _working = {};
  final Set<int> _cancelled = {};

  Timer? _timer;

  bool _processing = false;

  void Function(int page, RenderQuality quality, Uint8List data)? onImage;

  // ─────────────────────────────────────────────
  // PageItem က build/init ဖြစ်တဲ့အခါ
  // ─────────────────────────────────────────────

  void request(int page) {
    // already rendering
    if (_working.contains(page)) {
      return;
    }

    // already waiting
    if (_waiting.contains(page)) {
      return;
    }

    // cancel ထားတာဆို ပြန် active
    _cancelled.remove(page);

    _waiting.add(page);

    _schedule();
  }

  // ─────────────────────────────────────────────
  // PageItem dispose ဖြစ်တဲ့အခါ
  // ─────────────────────────────────────────────

  void cancel(int page) {
    _waiting.remove(page);

    // လက်ရှိ render မလုပ်ရသေးရင် cancel
    _cancelled.add(page);
  }

  // ─────────────────────────────────────────────

  void _schedule() {
    _timer?.cancel();

    _timer = Timer(const Duration(milliseconds: 500), _start);
  }

  void _start() {
    if (_processing) {
      return;
    }

    if (_waiting.isEmpty) {
      return;
    }

    _process();
  }

  Future<void> _process() async {
    if (_processing) {
      return;
    }

    _processing = true;

    try {
      while (_waiting.isNotEmpty) {
        // queue ထဲက တစ်ခုယူ
        final page = _waiting.first;

        _waiting.remove(page);

        // အဲ့ဒီ page က meanwhile cancel ဖြစ်သွားရင် skip
        if (_cancelled.contains(page)) {
          _cancelled.remove(page);
          continue;
        }

        _working.add(page);

        try {
          print('FETCH page=$page');

          final data = await render(page, RenderQuality.low);

          // render လုပ်နေတုန်း page ပျောက်သွားရင်
          // result ကို မသုံး
          if (_cancelled.contains(page)) {
            _cancelled.remove(page);

            print('IGNORE page=$page');

            continue;
          }

          print('DONE page=$page');

          onImage?.call(page, RenderQuality.low, data);
        } finally {
          _working.remove(page);
        }

        // တစ်ခုလုပ်ပြီးရင် ခဏစောင့်
        //
        // ဒီအချိန်အတွင်း PageItem အသစ်တွေ
        // request လုပ်လာနိုင်တယ်။
        if (_waiting.isNotEmpty) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      }
    } finally {
      _processing = false;

      if (_waiting.isNotEmpty) {
        _schedule();
      }
    }
  }

  void dispose() {
    _timer?.cancel();

    _waiting.clear();
    _working.clear();
    _cancelled.clear();
  }
}
