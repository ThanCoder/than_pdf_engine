import 'dart:async';
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

sealed class PageImageCacheEvent {
  const PageImageCacheEvent();
}

class PageImageCachePut extends PageImageCacheEvent {}

class PageImageCacheClear extends PageImageCacheEvent {}

class PageImageCacheRemove extends PageImageCacheEvent {
  final int pageIndex;
  const PageImageCacheRemove(this.pageIndex);
}

class PageImageCache {
  PageImageCache({
    this.maxCount = 200,
    this.maxSizeBytes = 10 * 1024 * 1024, // Default: 10 MB
  });
  final int maxCount;
  final int maxSizeBytes; // Max Cache Size ကို Bytes ဖြင့် သတ်မှတ်ရန်

  final _con = StreamController<PageImageCacheEvent>.broadcast();
  Stream<PageImageCacheEvent> get stream => _con.stream;

  final _cache = <int, PageImageCacheItem>{};

  int get len => _cache.length;

  int get size {
    return _cache.values.fold(0, (total, item) => total + item.data.length);
  }

  bool contains(int page, {double width = 0, double height = 0}) {
    final item = _cache[page];

    if (item == null) {
      return false;
    }

    return item.width == width && item.height == height;
  }

  void put(int page, Uint8List data, {double width = 0, double height = 0}) {
    // Existing item ကို remove လုပ်ပြီး
    // အသစ်ကို နောက်ဆုံးမှာထည့် → LRU
    _cache.remove(page);

    _cache[page] = PageImageCacheItem(data: data, width: width, height: height);

    // 🟢 Cache လွန်မလွန် စစ်ဆေးပြီး အဟောင်းများကို ဖျက်ထုတ်ခြင်း
    _evict();

    _con.add(PageImageCachePut());
  }

  Uint8List? get(int page, {double width = 0, double height = 0}) {
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

  // Count limit သို့မဟုတ် Size limit ကျော်လွန်ပါက အဟောင်းဆုံး Item များကို ဖျက်ပေးသည့် Function
  void _evict() {
    // Cache အရေအတွက် ကျော်လွန်နေလျှင် သို့မဟုတ် စုစုပေါင်း Size ကျော်လွန်နေလျှင် ဖျက်မည်
    while (_cache.isNotEmpty &&
        (_cache.length > maxCount || size > maxSizeBytes)) {
      final oldestKey =
          _cache.keys.first; // LRU အတိုင်း အဟောင်းဆုံး Key ကို ယူမည်
      _cache.remove(oldestKey);
    }
  }

  void remove(int page) {
    _cache.remove(page);
    _con.add(PageImageCacheRemove(page));
  }

  void clear() {
    _cache.clear();
    _con.add(PageImageCacheClear());
  }
}
