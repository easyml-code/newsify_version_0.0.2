import 'package:flutter/foundation.dart';
import '../config/config.dart';
import '../models/news_article.dart';
import 'insights_cache_manager.dart';

/// Service for handling insights tab operations
/// Includes: search, category filtering, and latest news fetching
/// With intelligent caching strategy similar to Inshorts
class InsightsService {
  static final InsightsService _instance = InsightsService._internal();
  factory InsightsService() => _instance;
  InsightsService._internal();

  final InsightsCacheManager _cacheManager = InsightsCacheManager();

  /// Fetch latest news for notifications (with caching)
  Future<List<NewsArticle>> fetchLatestNews({
    int limit = 20,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    // Check cache first (only for initial load, offset = 0)
    if (!forceRefresh && offset == 0) {
      final cached = _cacheManager.getLatestNews();
      if (cached != null && cached.length >= limit) {
        debugPrint('✅ Returning cached latest news');
        return cached.take(limit).toList();
      }
    }
    try {
      final supabase = AppConfig.supabase!;

      final response = await supabase.from('news_table').select('''
        news_author,
        image_url,
        news_title,
        news_location,
        news_url,
        provider,
        news_datetime,
        shorts_table!inner(
          shorts_header,
          shorts_body,
          category
        )
      ''')
          .order('news_datetime', ascending: false)
          .range(offset, offset + limit - 1);

      debugPrint('✅ Fetched ${response.length} latest news items');
      final articles = _parseNewsArticles(response);
      
      // Cache if it's initial load
      if (offset == 0 && articles.isNotEmpty) {
        _cacheManager.setLatestNews(articles);
      }
      
      return articles;
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching latest news: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to fetch latest news: $e');
    }
  }

  /// Search for news articles by query
  /// Uses text search on title and location
  /// NOTE: Search results are NOT cached (always fresh)
  Future<List<NewsArticle>> searchNews({
    required String query,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final supabase = AppConfig.supabase!;
      final searchQuery = query.trim().toLowerCase();

      if (searchQuery.isEmpty) {
        return [];
      }

      debugPrint('🔍 Searching for: $searchQuery');

      // Search in news_title and news_location (main table fields)
      // Then filter by shorts_table join
      // Using ilike for case-insensitive pattern matching
      final response = await supabase.from('news_table').select('''
        news_author,
        image_url,
        news_title,
        news_location,
        news_url,
        provider,
        news_datetime,
        shorts_table!inner(
          shorts_header,
          shorts_body,
          category
        )
      ''')
          .or('news_title.ilike.%$searchQuery%,news_location.ilike.%$searchQuery%')
          .order('news_datetime', ascending: false)
          .range(offset, offset + limit - 1);

      debugPrint('✅ Found ${response.length} results for "$searchQuery"');
      return _parseNewsArticles(response);
    } catch (e, stackTrace) {
      debugPrint('❌ Error searching news: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to search news: $e');
    }
  }

  /// Fetch news by category (with caching)
  /// Categories: my_feed, all_news, top_stories, trending
  Future<List<NewsArticle>> fetchCategoryNews({
    required String category,
    int limit = 20,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    // Check cache first (only for initial load, offset = 0)
    if (!forceRefresh && offset == 0) {
      final cached = _cacheManager.getCategoryNews(category);
      if (cached != null && cached.length >= limit) {
        debugPrint('✅ Returning cached $category data');
        return cached.take(limit).toList();
      }
    }
    try {
      final supabase = AppConfig.supabase!;

      final baseQuery = supabase.from('news_table').select('''
        news_author,
        image_url,
        news_title,
        news_location,
        news_url,
        provider,
        news_datetime,
        shorts_table!inner(
          shorts_header,
          shorts_body,
          category
        )
      ''');

      var query = baseQuery.order('news_datetime', ascending: false);

      switch (category) {
        case 'my_feed':
        case 'all_news':
        case 'top_stories':
        case 'trending':
        default:
          // You can still modify 'query' dynamically here
          break;
      }

      final response = await query.range(offset, offset + limit - 1);

      
      debugPrint('✅ Fetched ${response.length} items for category: $category');
      final articles = _parseNewsArticles(response);
      
      // Cache if it's initial load
      if (offset == 0 && articles.isNotEmpty) {
        _cacheManager.setCategoryNews(category, articles);
      }
      
      return articles;
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching category news: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to fetch category news: $e');
    }
  }

  /// Parse raw Supabase response into NewsArticle objects
  List<NewsArticle> _parseNewsArticles(List<dynamic> data) {
    if (data.isEmpty) {
      return [];
    }

    return data.map((item) {
      try {
        final newsAuthor = item['news_author']?.toString() ?? '';
        final imageUrl = item['image_url']?.toString() ?? '';
        final newsTitle = item['news_title']?.toString() ?? '';
        final publishedDatetime = item['news_datetime']?.toString();
        final newsUrl = item['news_url']?.toString() ?? '';
        final provider = item['provider']?.toString() ?? '';
        final location = item['news_location']?.toString() ?? '';

        // Parse datetime into timeAgo
        String timeAgo = 'Unknown time';
        if (publishedDatetime != null) {
          try {
            final createdDate = DateTime.parse(publishedDatetime);
            final now = DateTime.now();
            final difference = now.difference(createdDate);

            if (difference.inDays > 0) {
              timeAgo = '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
            } else if (difference.inHours > 0) {
              timeAgo = '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
            } else if (difference.inMinutes > 0) {
              timeAgo = '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
            } else {
              timeAgo = 'Just now';
            }
          } catch (e) {
            debugPrint('⚠️ Error parsing date: $e');
            timeAgo = 'Unknown time';
          }
        }

        // Get shorts data
        final shorts = item['shorts_table'];
        String shortsHeader = '';
        String shortsBody = '';
        String shortsCategory = '';

        if (shorts is List && shorts.isNotEmpty) {
          final firstShort = shorts[0];
          shortsHeader = firstShort['shorts_header']?.toString() ?? '';
          shortsBody = firstShort['shorts_body']?.toString() ?? '';
          shortsCategory = firstShort['category']?.toString() ?? '';
        } else if (shorts is Map) {
          shortsHeader = shorts['shorts_header']?.toString() ?? '';
          shortsBody = shorts['shorts_body']?.toString() ?? '';
          shortsCategory = shorts['category']?.toString() ?? '';
        }

        return NewsArticle(
          title: shortsHeader.isEmpty ? newsTitle : shortsHeader,
          content: shortsBody.isEmpty ? 'No content available' : shortsBody,
          author: newsAuthor.isEmpty ? 'Unknown' : newsAuthor,
          time: timeAgo,
          imageUrl: imageUrl,
          newsUrl: newsUrl,
          readMore: newsTitle.length > 40 ? newsTitle.substring(0, 40) : newsTitle,
          source: provider.isEmpty ? 'Unknown' : provider,
          location: location.isEmpty ? 'Unknown' : location,
        );
      } catch (e) {
        debugPrint('❌ Error parsing item: $e');
        return NewsArticle(
          title: 'Error loading article',
          content: 'Unable to load this article',
          author: 'Unknown',
          time: 'Unknown',
          imageUrl: '',
          newsUrl: '',
          readMore: 'Error',
          source: 'Unknown',
          location: 'Unknown',
        );
      }
    }).toList();
  }

  /// Get search suggestions based on partial query
  /// Returns list of suggested search terms
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      if (query.trim().isEmpty || query.length < 2) {
        return [];
      }

      final supabase = AppConfig.supabase!;
      final searchQuery = query.trim().toLowerCase();

      // Get unique titles and locations that match the query
      final response = await supabase
          .from('news_table')
          .select('news_title, news_location')
          .or('news_title.ilike.%$searchQuery%,news_location.ilike.%$searchQuery%')
          .limit(10);

      final suggestions = <String>{};

      for (var item in response) {
        final title = item['news_title']?.toString() ?? '';
        final location = item['news_location']?.toString() ?? '';

        // Add title if it matches
        if (title.toLowerCase().contains(searchQuery)) {
          suggestions.add(title);
        }

        // Add location if it matches
        if (location.toLowerCase().contains(searchQuery)) {
          suggestions.add(location);
        }

        if (suggestions.length >= 5) break;
      }

      return suggestions.toList();
    } catch (e) {
      debugPrint('❌ Error fetching suggestions: $e');
      return [];
    }
  }

  /// Pre-warm cache on app start (call this in main.dart or app initialization)
  Future<void> preWarmCache() async {
    await _cacheManager.preWarmCache(() => fetchCategoryNews(
          category: 'my_feed',
          limit: 50, // Cache more items for better UX
          offset: 0,
        ));
  }

  /// Clear cache for a specific category
  void clearCategoryCache(String category) {
    _cacheManager.clearCategory(category);
  }

  /// Clear all caches (useful on logout or settings change)
  void clearAllCache() {
    _cacheManager.clearAll();
  }

  /// Get cache statistics (for debugging)
  Map<String, dynamic> getCacheStats() {
    return _cacheManager.getCacheStats();
  }
}