import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/news_article.dart';
import '../config/config.dart';

/// Fetch shorts with optional category filter and random ordering
Future<List<NewsArticle>> fetchShorts({
  int limit = 20,
  int offset = 0,
  String? category,
  bool randomizeOrder = true,
}) async {
  try {
    final supabase = AppConfig.supabase!;

    // Build base query
    var query = supabase.from('news_table').select('''
      news_author,
      image_url,
      news_title,
      news_url,
      provider,
      news_datetime,
      shorts_table!inner(
        shorts_header,
        shorts_body,
        category
      )
    ''');

    // Add category filter if specified
    if (category != null && category.isNotEmpty) {
      query = query.eq('shorts_table.category', category);
      debugPrint('🔍 Filtering by category: $category');
    }

    // Fetch slightly more items than needed for randomization
    final fetchLimit = randomizeOrder ? limit + 10 : limit;
    
    // Apply ordering and range - do this in one chain without reassigning
    final response = await query
        .order('news_datetime', ascending: false)
        .range(offset, offset + fetchLimit - 1);

    debugPrint('✅ Supabase response: ${response.length} items (offset: $offset, limit: $limit, category: ${category ?? "all"})');

    var data = response as List<dynamic>;

    if (data.isEmpty) {
      debugPrint('⚠️ No shorts found in database');
      return [];
    }

    // Apply light randomization to recent news
    if (randomizeOrder && data.length > limit) {
      data = _applyLightRandomization(data, limit);
    } else if (data.length > limit) {
      data = data.sublist(0, limit);
    }

    return data.map((item) {
      try {
        final newsAuthor = item['news_author']?.toString() ?? '';
        final imageUrl = item['image_url']?.toString() ?? '';
        final newsTitle = item['news_title']?.toString() ?? '';
        final publishedDatetime = item['news_datetime']?.toString();
        final newsUrl = item['news_url']?.toString() ?? '';
        final provider = item['provider']?.toString() ?? '';

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
          readMore: newsTitle.length > 30 ? newsTitle.substring(0, 30) : newsTitle,
          source: provider.isEmpty ? 'Unknown' : provider,
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
        );
      }
    }).toList();
  } catch (e, stackTrace) {
    debugPrint('❌ Error fetching shorts: $e');
    debugPrint('Stack trace: $stackTrace');
    throw Exception('Error fetching shorts: $e');
  }
}

/// Apply light randomization to keep content fresh
/// Keeps the most recent news at top but slightly shuffles the order
List<dynamic> _applyLightRandomization(List<dynamic> data, int limit) {
  final random = Random();
  final result = <dynamic>[];

  // Keep first 3 items in order (most recent news)
  final topItems = data.take(3).toList();
  result.addAll(topItems);

  // Take next items and apply light shuffle
  final remainingData = data.skip(3).toList();
  
  while (result.length < limit && remainingData.isNotEmpty) {
    // Pick from top 5 items randomly (not fully random, weighted towards recent)
    final pickFrom = min(5, remainingData.length);
    final randomIndex = random.nextInt(pickFrom);
    
    result.add(remainingData[randomIndex]);
    remainingData.removeAt(randomIndex);
  }

  debugPrint('🔀 Applied light randomization: ${result.length} items');
  return result;
}