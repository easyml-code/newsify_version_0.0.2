// import 'dart:nativewrappers/_internal/vm/lib/internal_patch.dart';

import 'package:flutter/foundation.dart';
import '../models/news_article.dart';
import '../config/config.dart';

Future<List<NewsArticle>> fetchShorts({int limit = 20, int offset = 0}) async {
  try {
    final supabase = AppConfig.supabase!;

    // Query with pagination support
    final response = await supabase
        .from('news_table')
        .select('''
          news_author,
          image_url,
          news_title,
          news_url,
          provider,
          news_datetime,
          shorts_table(
            shorts_header,
            shorts_body
          )
        ''')
        .order('news_datetime', ascending: false)
        .range(offset, offset + limit - 1);

    debugPrint('✅ Supabase response: ${response.length} items (offset: $offset, limit: $limit)');

    // Response is directly the data list
    final data = response as List<dynamic>;

    if (data.isEmpty) {
      debugPrint('⚠️ No shorts found in database');
      return [];
    }

    return data.map((item) {
      try {
        // Directly read news fields from item
        final newsAuthor = item['news_author']?.toString() ?? '';
        final imageUrl = item['image_url']?.toString() ?? '';
        final newsTitle = item['news_title']?.toString() ?? '';
        final publishedDatetime = item['news_datetime']?.toString();
        final newsUrl = item['news_url']?.toString() ?? '';
        final provider = item['provider']?.toString() ?? '';

        // Parse created_datetime into timeAgo
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

        // Take the first short as title/content
        final shorts = item['shorts_table'] as List<dynamic>? ?? [];
        final firstShort = shorts.isNotEmpty ? shorts[0] : null;

        // Ensure we have at least shorts data
        if (firstShort == null) {
          debugPrint('⚠️ No shorts_table data for: $newsTitle');
        }

        return NewsArticle(
          title: firstShort?['shorts_header']?.toString() ?? newsTitle,
          content: firstShort?['shorts_body']?.toString() ?? 'No content available',
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

// Fetch only shorts with specific category (for filtering)
Future<List<NewsArticle>> fetchShortsByCategory(String category, {int limit = 20, int offset = 0}) async {
  try {
    final supabase = AppConfig.supabase!;

    final response = await supabase
        .from('news_table')
        .select('''
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
        ''')
        .eq('shorts_table.category', category)
        .order('news_datetime', ascending: false)
        .range(offset, offset + limit - 1);

    debugPrint('✅ Category filter response: ${response.length} items for $category');

    final data = response as List<dynamic>;

    return data.map((item) {
      final newsAuthor = item['news_author']?.toString() ?? '';
      final imageUrl = item['image_url']?.toString() ?? '';
      final newsTitle = item['news_title']?.toString() ?? '';
      final publishedDatetime = item['news_datetime']?.toString();
      final newsUrl = item['news_url']?.toString() ?? '';
      final provider = item['provider']?.toString() ?? '';

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
          timeAgo = 'Unknown time';
        }
      }

      final shorts = item['shorts_table'] as List<dynamic>? ?? [];
      final firstShort = shorts.isNotEmpty ? shorts[0] : null;

      return NewsArticle(
        title: firstShort?['shorts_header']?.toString() ?? newsTitle,
        content: firstShort?['shorts_body']?.toString() ?? 'No content',
        author: newsAuthor.isEmpty ? '' : newsAuthor,
        time: timeAgo,
        imageUrl: imageUrl,
        newsUrl: newsUrl,
        readMore: newsTitle.length > 30 ? newsTitle.substring(0, 30) : newsTitle,
        source: provider.isEmpty ? 'Unknown' : provider,
      );
    }).toList();
  } catch (e) {
    debugPrint('❌ Error fetching shorts by category: $e');
    throw Exception('Error fetching shorts: $e');
  }
}