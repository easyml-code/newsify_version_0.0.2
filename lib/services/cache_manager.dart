import 'package:flutter/foundation.dart';
import '../models/news_article.dart';

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final Map<String, List<NewsArticle>> _categoryCache = {};
  final Map<String, CacheMetadata> _cacheMetadata = {};

  List<NewsArticle>? getCachedShorts(String category) {
    return _categoryCache[category];
  }

  bool hasCachedShorts(String category) {
    return _categoryCache.containsKey(category) && 
           _categoryCache[category]!.isNotEmpty;
  }

  void cacheShorts(String category, List<NewsArticle> shorts) {
    _categoryCache[category] = shorts;
    _cacheMetadata[category] = CacheMetadata(
      lastUpdated: DateTime.now(),
      itemCount: shorts.length,
    );
    debugPrint('📦 Cached ${shorts.length} shorts for category: $category');
  }

  void appendShorts(String category, List<NewsArticle> newShorts) {
    if (_categoryCache[category] == null) {
      cacheShorts(category, newShorts);
      return;
    }

    final existingUrls = _categoryCache[category]!.map((s) => s.newsUrl).toSet();
    final uniqueShorts = newShorts
        .where((s) => !existingUrls.contains(s.newsUrl))
        .toList();

    _categoryCache[category]!.addAll(uniqueShorts);
    _cacheMetadata[category] = CacheMetadata(
      lastUpdated: DateTime.now(),
      itemCount: _categoryCache[category]!.length,
    );
    
    debugPrint('📦 Added ${uniqueShorts.length} more shorts to $category. Total: ${_categoryCache[category]!.length}');
  }

  CacheMetadata? getCacheMetadata(String category) {
    return _cacheMetadata[category];
  }

  void clearCategory(String category) {
    _categoryCache.remove(category);
    _cacheMetadata.remove(category);
    debugPrint('🗑️ Cleared cache for category: $category');
  }

  void clearAll() {
    _categoryCache.clear();
    _cacheMetadata.clear();
    debugPrint('🗑️ Cleared all caches');
  }

  List<String> getCachedCategories() {
    return _categoryCache.keys.toList();
  }

  int getTotalCachedItems() {
    return _categoryCache.values.fold(0, (sum, list) => sum + list.length);
  }

  bool isCacheStale(String category, Duration staleDuration) {
    final metadata = _cacheMetadata[category];
    if (metadata == null) return true;
    
    return DateTime.now().difference(metadata.lastUpdated) > staleDuration;
  }
}

class CacheMetadata {
  final DateTime lastUpdated;
  final int itemCount;

  CacheMetadata({
    required this.lastUpdated,
    required this.itemCount,
  });

  Duration get age => DateTime.now().difference(lastUpdated);
}