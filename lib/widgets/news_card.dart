import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/news_article.dart';
import '../services/auth_service.dart';
import '../services/share_service.dart';
import '../screens/auth/auth_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

class NewsCard extends StatefulWidget {
  final NewsArticle article;

  const NewsCard({super.key, required this.article});

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  final AuthService _authService = AuthService();
  final GlobalKey _screenshotKey = GlobalKey();
  
  bool _isBookmarked = false;
  bool _isCheckingBookmark = true;
  bool _isSharing = false;

  // TODO: Replace with actual theme mode when you add that feature
  bool get isDarkMode => true; // Currently always dark, change this later

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    if (_authService.isSignedIn) {
      final isBookmarked = await _authService.isBookmarked(widget.article.newsUrl);
      if (mounted) {
        setState(() {
          _isBookmarked = isBookmarked;
          _isCheckingBookmark = false;
        });
      }
    } else {
      setState(() => _isCheckingBookmark = false);
    }
  }

  Future<void> _handleBookmark() async {
    if (!_authService.isSignedIn) {
      if (mounted) {
        AuthScreen.showAuthBottomSheet(context);
      }
      return;
    }

    try {
      if (_isBookmarked) {
        await _authService.removeBookmark(widget.article.newsUrl);
        if (mounted) {
          setState(() => _isBookmarked = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from bookmarks'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await _authService.addBookmark(
          widget.article.newsUrl,
          widget.article.title,
          widget.article.imageUrl,
        );
        if (mounted) {
          setState(() => _isBookmarked = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to bookmarks'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleShareWithContext(BuildContext buttonContext) async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    try {
      await ShareService.shareWithButtonContext(
        screenshotKey: _screenshotKey,
        buttonContext: buttonContext,
        title: widget.article.title,
        url: widget.article.newsUrl,
      );
    } catch (e) {
      debugPrint('Error sharing: $e');
      if (mounted) {
        await ShareService.shareTextOnly(
          title: widget.article.title,
          url: widget.article.newsUrl,
          context: buttonContext,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

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
    return Stack(
      children: [
        // Main visible card
        _buildVisibleCard(),
        
        // Hidden screenshot layer (positioned off-screen, never visible)
        Positioned(
          left: -10000,
          top: 0,
          child: RepaintBoundary(
            key: _screenshotKey,
            child: _buildShareableContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildVisibleCard() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Column(
            children: [
              // 🖼 Image Section
              Container(
                height: MediaQuery.of(context).size.height * 0.35,
                width: double.infinity,
                padding: const EdgeInsets.only(top: 12),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.network(
                        widget.article.imageUrl,
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
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.white, size: 26),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),

              // 📰 Content Section
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 25, 18, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.article.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.article.content,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.article.author != 'Unknown'
                            ? '${widget.article.time} | ${widget.article.author} | ${widget.article.source}'
                            : '${widget.article.time} | ${widget.article.source}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Badge at top left - SAME POSITION IN BOTH VIEWS
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35 - 16,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/app/app_logo.png',
                      width: 18, 
                      height: 18, 
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Newsify',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bookmark and Share buttons (ONLY in visible card)
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
                    onTap: _handleBookmark,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      child: _isCheckingBookmark
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: _isBookmarked ? const Color(0xFF2196F3) : Colors.white,
                              size: 22,
                            ),
                    ),
                  ),
                  Builder(
                    builder: (buttonContext) => GestureDetector(
                      onTap: _isSharing ? null : () => _handleShareWithContext(buttonContext),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: _isSharing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.share, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // "Tap to know more" section (ONLY in visible card)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _launchURL(widget.article.newsUrl),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    Image.network(
                      widget.article.imageUrl,
                      width: double.infinity,
                      height: 80,
                      fit: BoxFit.none,
                    ),
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 0),
                      child: Container(
                        height: 80,
                        color: Colors.black.withOpacity(0.70),
                      ),
                    ),
                    Container(
                      height: 80,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.article.readMore,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to know more',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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


Widget _buildShareableContent() {
  final screenWidth = MediaQuery.of(context).size.width;
  final imageHeight = MediaQuery.of(context).size.height * 0.35;

  // Theme-based colors
  final backgroundColor = isDarkMode ? Colors.black : Colors.white;
  final textColor = isDarkMode ? Colors.white : Colors.black;
  final subtitleColor = isDarkMode ? Colors.grey[300] : Colors.grey[800];
  final metaColor = isDarkMode ? Colors.grey[600] : Colors.grey[500];

  return Stack(
    children: [
      // Main content in Column
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          SizedBox(
            height: imageHeight,
            width: screenWidth,
            child: Image.network(
              widget.article.imageUrl,
              width: screenWidth,
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

          // Content section
          Container(
            width: screenWidth,
            padding: const EdgeInsets.fromLTRB(18, 25, 18, 10),
            color: backgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.article.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.article.content,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.article.author != 'Unknown'
                      ? '${widget.article.time} | ${widget.article.author} | ${widget.article.source}'
                      : '${widget.article.time} | ${widget.article.source}',
                  style: TextStyle(
                    color: metaColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Footer
          Container(
            width: screenWidth,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(
                top: BorderSide(
                  color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/badges/playstore_badge.png',
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 6),
                    Image.asset(
                      'assets/badges/appstore_badge.png',
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Image.asset(
                      'assets/app/app_logo.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Newsify',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      // Independent brand badge (positioned)
      Positioned(
        top: imageHeight - 8,
        left: 12,
        child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/app/app_logo.png',
                      width: 18, 
                      height: 18, 
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Newsify',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
      ),
    ],
  );
}

}