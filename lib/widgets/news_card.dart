import 'package:flutter/material.dart';
import '../models/news_article.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsCard extends StatelessWidget {
  final NewsArticle article;

  const NewsCard({super.key, required this.article});

  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        debugPrint('Cannot launch URL: $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Column(
            children: [
              // 🖼 Image Section - FIXED HEIGHT
              Container(
                height: MediaQuery.of(context).size.height * 0.35,
                width: double.infinity,
                padding: const EdgeInsets.only(top: 12),
                child: Stack(
                  children: [
                    // Image with rounded corners
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),   
                        topRight: Radius.circular(16), 
                      ),
                      child: Image.network(
                        article.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[850],
                            child: const Center(
                              child: Icon(Icons.image, size: 60, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),

                    // More options button at top right
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.white, size: 26),
                        onPressed: () {
                          // Show options menu
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 📰 Scrollable Content Section
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 25, 18, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        article.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Content
                      Text(
                        article.content,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Meta info
                      Text(
                        article.author != 'Unknown'
                        ? '${article.time} | ${article.author} | ${article.source}'
                        : '${article.time} | ${article.source}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 90), // Space for "Tap to know more"
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bookmark and Share buttons - POSITIONED AT IMAGE/TEXT BORDER
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35 - 16,
            right: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(60),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Handle bookmark
                      debugPrint('Bookmark tapped');
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      child: Icon(Icons.bookmark_border, color: Colors.white, size: 22),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Handle share
                      debugPrint('Share tapped');
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.share, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
                              // Badge at top left
                    // Positioned(
                    //   top: MediaQuery.of(context).size.height * 0.35 - 18,
                    //   left: 20,
                    //   child: Container(
                    //     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    //     decoration: BoxDecoration(
                    //       // color: Colors.black.withOpacity(0.7),
                    //       color: Colors.grey,
                    //       borderRadius: BorderRadius.circular(60),
                    //     ),
                    //     child: Row(
                    //       mainAxisSize: MainAxisSize.min,
                    //       children: [
                    //         Container(
                    //           width: 14,
                    //           height: 14,
                    //           decoration: const BoxDecoration(
                    //             color: Colors.white,
                    //             shape: BoxShape.circle,
                    //           ),
                    //           child: const Center(
                    //             child: Icon(
                    //               Icons.article,
                    //               size: 8,
                    //               color: Colors.black,
                    //             ),
                    //           ),
                    //         ),
                    //         const SizedBox(width: 6),
                    //         const Text(
                    //           'newsify',
                    //           style: TextStyle(
                    //             color: Colors.white,
                    //             fontSize: 12,
                    //             fontWeight: FontWeight.bold,
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),

          // "Tap to know more" button - FIXED AT BOTTOM
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                _launchURL(article.newsUrl);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 0),
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.grey[900]?.withOpacity(0.6),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),   
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Tap to know more',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      article.readMore,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}