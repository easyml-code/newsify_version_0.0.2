import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../screens/news_detail_screen.dart';

/// A compact news item widget for the insights tab
/// Shows image, title, and metadata in a horizontal layout
class InsightsNewsItem extends StatelessWidget {
  final NewsArticle article;
  final bool isDarkMode;

  const InsightsNewsItem({
    super.key,
    required this.article,
    required this.isDarkMode,
  });

  void _openNewsDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(
          newsUrl: article.newsUrl,
          title: article.title,
          imageUrl: article.imageUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openNewsDetail(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text content (left side)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    article.title,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Metadata
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${article.time} • ${article.source}',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  // Location if available
                  if (article.location != null && 
                      article.location != 'Unknown' &&
                      article.location!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            article.location!,
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Image (right side)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: article.imageUrl.isNotEmpty
                  ? Image.network(
                      article.imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    )
                  : _buildPlaceholderImage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 100,
      height: 100,
      color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
      child: Icon(
        Icons.image,
        color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
        size: 40,
      ),
    );
  }
}