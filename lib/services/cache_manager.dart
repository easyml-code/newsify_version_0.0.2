import 'package:flutter/foundation.dart';
import '../models/news_article.dart';

/// Global cache manager for storing shorts across the app session
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  // Cache structure: category -> list of articles
  final Map<String, List<NewsArticle>> _categoryCache = {};
  
  // Metadata for each category
  final Map<String, CacheMetadata> _cacheMetadata = {};

  /// Get cached shorts for a category
  List<NewsArticle>? getCachedShorts(String category) {
    return _categoryCache[category];
  }

  /// Check if cache exists and is valid for a category
  bool hasCachedShorts(String category) {
    return _categoryCache.containsKey(category) && 
           _categoryCache[category]!.isNotEmpty;
  }

  /// Cache shorts for a category
  void cacheShorts(String category, List<NewsArticle> shorts) {
    _categoryCache[category] = shorts;
    _cacheMetadata[category] = CacheMetadata(
      lastUpdated: DateTime.now(),
      itemCount: shorts.length,
    );
    debugPrint('📦 Cached ${shorts.length} shorts for category: $category');
  }

  /// Add more shorts to existing cache (for pagination)
  void appendShorts(String category, List<NewsArticle> newShorts) {
    if (_categoryCache[category] == null) {
      cacheShorts(category, newShorts);
      return;
    }

    // Remove duplicates
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

  /// Get cache metadata for a category
  CacheMetadata? getCacheMetadata(String category) {
    return _cacheMetadata[category];
  }

  /// Clear cache for a specific category
  void clearCategory(String category) {
    _categoryCache.remove(category);
    _cacheMetadata.remove(category);
    debugPrint('🗑️ Cleared cache for category: $category');
  }

  /// Clear all caches
  void clearAll() {
    _categoryCache.clear();
    _cacheMetadata.clear();
    debugPrint('🗑️ Cleared all caches');
  }

  /// Get all cached categories
  List<String> getCachedCategories() {
    return _categoryCache.keys.toList();
  }

  /// Get total cached items across all categories
  int getTotalCachedItems() {
    return _categoryCache.values.fold(0, (sum, list) => sum + list.length);
  }

  /// Check if cache is stale (older than specified duration)
  bool isCacheStale(String category, Duration staleDuration) {
    final metadata = _cacheMetadata[category];
    if (metadata == null) return true;
    
    return DateTime.now().difference(metadata.lastUpdated) > staleDuration;
  }
}

/// Metadata about cached data
class CacheMetadata {
  final DateTime lastUpdated;
  final int itemCount;

  CacheMetadata({
    required this.lastUpdated,
    required this.itemCount,
  });

  Duration get age => DateTime.now().difference(lastUpdated);
}