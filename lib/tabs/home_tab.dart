import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../widgets/news_card.dart';
import '../data/shorts_data.dart';

class HomeTab extends StatefulWidget {
  final bool isLocalSelected;
  final VoidCallback onLocalToggle;

  const HomeTab({
    super.key,
    required this.isLocalSelected,
    required this.onLocalToggle,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Cache management
  List<NewsArticle>? _cachedShorts; // Cache the shorts
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentOffset = 0;
  final int _pageSize = 20;
  bool _hasMoreData = true;

  final List<String> categories = [
    'Feed',
    'Finance',
    'Timelines',
    'Videos',
    'Insights'
  ];

  @override
  bool get wantKeepAlive => true; // Keep state alive

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _loadInitialShorts();

    // Listen to page changes to load more when near end
    _pageController.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    if (_pageController.hasClients && _cachedShorts != null) {
      final maxScroll = _pageController.position.maxScrollExtent;
      final currentScroll = _pageController.position.pixels;
      final delta = maxScroll - currentScroll;

      // Load more when user is 3 items away from the end
      if (delta <= 3 * MediaQuery.of(context).size.height &&
          !_isLoadingMore &&
          _hasMoreData) {
        _loadMoreShorts();
      }
    }
  }

  Future<void> _loadInitialShorts() async {
    if (_cachedShorts != null) {
      // Already loaded, don't fetch again
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final shorts = await fetchShorts();
      _currentOffset += shorts.length;
      
      if (mounted) {
        setState(() {
          _cachedShorts = shorts;
          _isLoading = false;
          _currentOffset = shorts.length;
          _hasMoreData = shorts.length >= _pageSize;
        });
        debugPrint('✅ Initial load: ${shorts.length} shorts');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading news: $e';
        });
        debugPrint('❌ Error loading initial shorts: $e');
      }
    }
  }

  Future<void> _loadMoreShorts() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // In a real app, you'd pass offset/limit to fetch next batch
      // For now, we'll simulate by fetching again
      
      final moreShorts = await fetchShorts(offset: _currentOffset, limit: _pageSize);
      _currentOffset += moreShorts.length;

      if (mounted) {
        setState(() {
          if (moreShorts.isNotEmpty) {
            // Remove duplicates and add new shorts
            final existingUrls = _cachedShorts!.map((s) => s.newsUrl).toSet();
            final newShorts = moreShorts
                .where((s) => !existingUrls.contains(s.newsUrl))
                .toList();
            
            _cachedShorts!.addAll(newShorts);
            _currentOffset += newShorts.length;
            _hasMoreData = newShorts.isNotEmpty && newShorts.length >= _pageSize;
          } else {
            _hasMoreData = false;
          }
          _isLoadingMore = false;
        });
        debugPrint('✅ Loaded more: ${moreShorts.length} shorts, total: ${_cachedShorts!.length}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        debugPrint('❌ Error loading more shorts: $e');
      }
    }
  }

  Future<void> _refreshShorts() async {
    setState(() {
      _cachedShorts = null; // Clear cache
      _currentOffset = 0;
      _hasMoreData = true;
    });
    await _loadInitialShorts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Category tabs at the top with Local button
            Container(
              color: Colors.black,
              child: Stack(
                children: [
                  Row(
                    children: [
                      // Static Local button
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 12, top: 12, bottom: 12),
                        child: GestureDetector(
                          onTap: widget.onLocalToggle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.isLocalSelected
                                  ? const Color(0xFF2196F3).withOpacity(0.15)
                                  : Colors.grey[900],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: widget.isLocalSelected
                                    ? const Color(0xFF2196F3)
                                    : Colors.grey[800]!,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Local',
                              style: TextStyle(
                                color: widget.isLocalSelected
                                    ? const Color(0xFF2196F3)
                                    : Colors.grey[400],
                                fontSize: 14,
                                fontWeight: widget.isLocalSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Small gap
                      const SizedBox(width: 8),
                      // Scrollable tabs
                      Expanded(
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          indicatorColor: Colors.transparent,
                          dividerColor: Colors.transparent,
                          labelColor: const Color(0xFF2196F3),
                          unselectedLabelColor: Colors.grey[600],
                          labelStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                          labelPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          tabAlignment: TabAlignment.start,
                          padding: EdgeInsets.zero,
                          tabs: categories
                              .map((category) => Text(category))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                  // Gradient fade effect
                  Positioned(
                    left: 80,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black,
                              Colors.black.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // News cards
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Initial loading
    if (_isLoading && _cachedShorts == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2196F3),
        ),
      );
    }

    // Error state
    if (_errorMessage != null && _cachedShorts == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Error loading news',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadInitialShorts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (_cachedShorts == null || _cachedShorts!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 60, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No news available',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for updates',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refreshShorts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    // Content loaded - show with pull to refresh
    return RefreshIndicator(
      onRefresh: _refreshShorts,
      color: const Color(0xFF2196F3),
      backgroundColor: Colors.grey[900],
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: _cachedShorts!.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at the end
          if (index == _cachedShorts!.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF2196F3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading more...',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Transform.translate(
            offset: const Offset(0, -10),
            child: NewsCard(article: _cachedShorts![index]),
          );
        },
      ),
    );
  }
}