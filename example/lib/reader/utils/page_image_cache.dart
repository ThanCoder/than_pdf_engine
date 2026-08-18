import 'dart:typed_data';

class PageImageCacheItem {
  final Uint8List data;
  final double width;
  final double height;

  const PageImageCacheItem({
    required this.data,
    required this.width,
    required this.height,
  });
}

class PageImageCache {
  final int maxCount;

  PageImageCache({this.maxCount = 10});

  final _cache = <int, PageImageCacheItem>{};

  int get len => _cache.length;

  int get size {
    return _cache.values.fold(0, (total, item) => total + item.data.length);
  }

  bool contains(int page, {required double width, required double height}) {
    final item = _cache[page];

    if (item == null) {
      return false;
    }

    return item.width == width && item.height == height;
  }

  void put(
    int page,
    Uint8List data, {
    required double width,
    required double height,
  }) {
    // Existing item ကို remove လုပ်ပြီး
    // အသစ်ကို နောက်ဆုံးမှာထည့် → LRU
    _cache.remove(page);

    _cache[page] = PageImageCacheItem(data: data, width: width, height: height);

    while (_cache.length > maxCount) {
      _cache.remove(_cache.keys.first);
    }
  }

  Uint8List? get(int page, {required double width, required double height}) {
    final item = _cache[page];

    if (item == null) {
      return null;
    }

    // Render size မတူရင် old image မသုံး
    if (item.width != width || item.height != height) {
      _cache.remove(page);
      return null;
    }

    // Access လုပ်ထားတဲ့ item ကို newest ဖြစ်အောင်
    _cache.remove(page);
    _cache[page] = item;

    return item.data;
  }

  void remove(int page) {
    _cache.remove(page);
  }

  void clear() {
    _cache.clear();
  }
}
