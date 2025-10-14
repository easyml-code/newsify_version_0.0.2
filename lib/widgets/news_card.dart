import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/news_article.dart';
import '../services/auth_service.dart';
import '../services/share_service.dart';
import '../screens/auth/auth_screen.dart';
import '../providers/theme_provider.dart';
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

  // Get theme from provider
  bool get isDarkMode => Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDarkMode = themeProvider.isDarkMode;
        
        return Stack(
          children: [
            // Main visible card
            _buildVisibleCard(isDarkMode),
            
            // Hidden screenshot layer (positioned off-screen, never visible)
            Positioned(
              left: -10000,
              top: 0,
              child: RepaintBoundary(
                key: _screenshotKey,
                child: _buildShareableContent(isDarkMode),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVisibleCard(bool isDarkMode) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: Colors.black, // Black background for rounded corners
        child: Container(
          color: isDarkMode ? Colors.black : Colors.white,
          child: Stack(
            children: [
              Column(
                children: [
                  // 🖼 Image Section
                  Container(
                    height: MediaQuery.of(context).size.height * 0.35,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Image.network(
                          widget.article.imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: isDarkMode ? Colors.grey[850] : Colors.grey[300],
                              child: Center(
                                child: Icon(
                                  Icons.image,
                                  size: 60,
                                  color: isDarkMode ? Colors.grey : Colors.grey[600],
                                ),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: Icon(
                              Icons.more_horiz,
                              color: isDarkMode ? Colors.white : Colors.black,
                              size: 26,
                            ),
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
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.article.content,
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
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
                              color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
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
                top: MediaQuery.of(context).size.height * 0.35 - 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: !isDarkMode ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
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
                      Text(
                        'Newsify',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
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
                    color: isDarkMode ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: !isDarkMode ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
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
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                )
                              : Icon(
                                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                  color: _isBookmarked 
                                      ? const Color(0xFF2196F3) 
                                      : (isDarkMode ? Colors.white : Colors.black),
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
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                  )
                                : Icon(
                                      Icons.share,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                      size: 22,
                                    ),
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
                            color: (isDarkMode ? Colors.black : Colors.white).withOpacity(0.70),
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
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
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
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
              ),),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareableContent(bool isDarkMode) {
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
          top: imageHeight - 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black : Colors.white,
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
                Text(
                  'Newsify',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
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