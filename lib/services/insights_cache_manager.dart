import 'package:flutter/foundation.dart';
import '../models/news_article.dart';

/// Caching strategy for Insights Tab
/// Similar to Inshorts approach: Cache data locally, fetch on demand
/// 
/// Strategy:
/// 1. Cache latest news (for notifications) - 30 minutes TTL
/// 2. Cache category data separately - 30 minutes TTL
/// 3. Don't cache search results (always fresh)
/// 4. Pre-warm cache on app start for My Feed
/// 5. Clear cache on pull-to-refresh
class InsightsCacheManager {
  static final InsightsCacheManager _instance = InsightsCacheManager._internal();
  factory InsightsCacheManager() => _instance;
  InsightsCacheManager._internal();

  // Cache storage with metadata
  final Map<String, CachedData<List<NewsArticle>>> _cache = {};
  
  // Cache TTL (Time To Live)
  static const Duration _cacheDuration = Duration(minutes: 30);
  
  // Cache keys
  static const String _latestNewsKey = 'latest_news';
  static const String _myFeedKey = 'my_feed';
  static const String _allNewsKey = 'all_news';
  static const String _topStoriesKey = 'top_stories';
  static const String _trendingKey = 'trending';

  /// Get cached data if valid, otherwise return null
  List<NewsArticle>? get(String key) {
    final cached = _cache[key];
    
    if (cached == null) {
      debugPrint('📦 Cache miss for: $key');
      return null;
    }

    if (cached.isExpired) {
      debugPrint('⏰ Cache expired for: $key (age: ${cached.age.inMinutes}m)');
      _cache.remove(key);
      return null;
    }

    debugPrint('✅ Cache hit for: $key (age: ${cached.age.inMinutes}m, items: ${cached.data.length})');
    return cached.data;
  }

  /// Store data in cache
  void set(String key, List<NewsArticle> data) {
    _cache[key] = CachedData(
      data: data,
      timestamp: DateTime.now(),
      ttl: _cacheDuration,
    );
    debugPrint('💾 Cached $key: ${data.length} items');
  }

  /// Get latest news with caching
  List<NewsArticle>? getLatestNews() => get(_latestNewsKey);
  
  void setLatestNews(List<NewsArticle> data) => set(_latestNewsKey, data);

  /// Get category data with caching
  List<NewsArticle>? getCategoryNews(String category) {
    switch (category) {
      case 'my_feed':
        return get(_myFeedKey);
      case 'all_news':
        return get(_allNewsKey);
      case 'top_stories':
        return get(_topStoriesKey);
      case 'trending':
        return get(_trendingKey);
      default:
        return null;
    }
  }

  void setCategoryNews(String category, List<NewsArticle> data) {
    switch (category) {
      case 'my_feed':
        set(_myFeedKey, data);
        break;
      case 'all_news':
        set(_allNewsKey, data);
        break;
      case 'top_stories':
        set(_topStoriesKey, data);
        break;
      case 'trending':
        set(_trendingKey, data);
        break;
    }
  }

  /// Check if data is cached and valid
  bool isCached(String key) {
    return get(key) != null;
  }

  /// Clear specific cache
  void clear(String key) {
    _cache.remove(key);
    debugPrint('🗑️ Cleared cache: $key');
  }

  /// Clear category cache
  void clearCategory(String category) {
    switch (category) {
      case 'my_feed':
        clear(_myFeedKey);
        break;
      case 'all_news':
        clear(_allNewsKey);
        break;
      case 'top_stories':
        clear(_topStoriesKey);
        break;
      case 'trending':
        clear(_trendingKey);
        break;
    }
  }

  /// Clear all caches
  void clearAll() {
    _cache.clear();
    debugPrint('🗑️ Cleared all insights cache');
  }

  /// Pre-warm cache on app start (background task)
  /// This is what Inshorts does - load My Feed in background
  Future<void> preWarmCache(Future<List<NewsArticle>> Function() fetchMyFeed) async {
    try {
      debugPrint('🔥 Pre-warming insights cache...');
      final data = await fetchMyFeed();
      setLatestNews(data.take(10).toList()); // Cache first 10 for notifications
      setCategoryNews('my_feed', data);
      debugPrint('✅ Cache pre-warmed successfully');
    } catch (e) {
      debugPrint('❌ Cache pre-warm failed: $e');
      // Fail silently, user can still fetch on demand
    }
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    final stats = <String, dynamic>{};
    
    _cache.forEach((key, value) {
      stats[key] = {
        'items': value.data.length,
        'age_minutes': value.age.inMinutes,
        'expired': value.isExpired,
      };
    });
    
    return stats;
  }

  /// Memory usage estimation (approximate)
  int getMemoryUsageEstimate() {
    int totalItems = 0;
    _cache.forEach((_, value) {
      totalItems += value.data.length;
    });
    
    // Rough estimate: ~5KB per article (title, content, url, metadata)
    return totalItems * 5 * 1024; // bytes
  }
}

/// Cached data wrapper with metadata
class CachedData<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;

  CachedData({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });

  /// Check if cache is expired
  bool get isExpired {
    return DateTime.now().difference(timestamp) > ttl;
  }

  /// Get cache age
  Duration get age {
    return DateTime.now().difference(timestamp);
  }
}