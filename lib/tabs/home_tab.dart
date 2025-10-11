import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../widgets/news_card.dart';
import '../data/shorts_data.dart';
import '../services/cache_manager.dart';

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
  final CacheManager _cacheManager = CacheManager();
  
  int _currentPage = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentOffset = 0;
  final int _pageSize = 20;
  bool _hasMoreData = true;

  // Category mapping
  final Map<String, String> _categoryMapping = {
    'Feed': '',
    'Finance': 'Finance',
    'Timelines': 'Timelines',
    'Videos': 'Videos',
    'Insights': 'Insights',
  };

  final List<String> categories = [
    'Feed',
    'Finance',
    'Timelines',
    'Videos',
    'Insights'
  ];

  String get _currentCategory => categories[_tabController.index];
  String? get _currentCategoryFilter => _categoryMapping[_currentCategory];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    
    // Listen to tab changes
    _tabController.addListener(_onTabChanged);
    
    // Load initial data for Feed
    _loadShortsForCurrentCategory();

    // Listen to page changes for pagination
    _pageController.addListener(_onPageScroll);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      debugPrint('📑 Tab changed to: $_currentCategory');
      _loadShortsForCurrentCategory();
    }
  }

  void _onPageScroll() {
    final cachedShorts = _cacheManager.getCachedShorts(_currentCategory);
    
    if (_pageController.hasClients && cachedShorts != null) {
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

  Future<void> _loadShortsForCurrentCategory() async {
    // Check if we have cached data for this category
    if (_cacheManager.hasCachedShorts(_currentCategory)) {
      debugPrint('✅ Using cached data for $_currentCategory');
      setState(() {
        _errorMessage = null;
      });
      return;
    }

    // No cache, fetch from database
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentOffset = 0;
      _hasMoreData = true;
    });

    try {
      final shorts = await fetchShorts(
        limit: _pageSize,
        offset: 0,
        category: _currentCategoryFilter,
        randomizeOrder: true,
      );

      if (mounted) {
        // Cache the fetched shorts
        _cacheManager.cacheShorts(_currentCategory, shorts);
        _currentOffset = shorts.length;
        
        setState(() {
          _isLoading = false;
          _hasMoreData = shorts.length >= _pageSize;
        });
        
        debugPrint('✅ Loaded ${shorts.length} shorts for $_currentCategory');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading news: $e';
        });
        debugPrint('❌ Error loading shorts: $e');
      }
    }
  }

  Future<void> _loadMoreShorts() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final moreShorts = await fetchShorts(
        offset: _currentOffset,
        limit: _pageSize,
        category: _currentCategoryFilter,
        randomizeOrder: true,
      );

      if (mounted) {
        if (moreShorts.isNotEmpty) {
          // Append to cache
          _cacheManager.appendShorts(_currentCategory, moreShorts);
          _currentOffset += moreShorts.length;
          _hasMoreData = moreShorts.length >= _pageSize;
        } else {
          _hasMoreData = false;
        }
        
        setState(() {
          _isLoadingMore = false;
        });
        
        debugPrint('✅ Loaded ${moreShorts.length} more shorts');
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
    // Clear cache for current category
    _cacheManager.clearCategory(_currentCategory);
    _currentOffset = 0;
    _hasMoreData = true;
    
    await _loadShortsForCurrentCategory();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Category tabs with Local button
            Container(
              color: Colors.black,
              child: Stack(
                children: [
                  Row(
                    children: [
                      // Static Local button
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
                        child: GestureDetector(
                          onTap: widget.onLocalToggle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
                          labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          tabAlignment: TabAlignment.start,
                          padding: EdgeInsets.zero,
                          tabs: categories.map((category) {
                            // Show cache indicator
                            final hasCached = _cacheManager.hasCachedShorts(category);
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(category),
                                if (hasCached) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2196F3),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            );
                          }).toList(),
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
    final cachedShorts = _cacheManager.getCachedShorts(_currentCategory);

    // Initial loading
    if (_isLoading && cachedShorts == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2196F3),
        ),
      );
    }

    // Error state
    if (_errorMessage != null && cachedShorts == null) {
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
              onPressed: _loadShortsForCurrentCategory,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (cachedShorts == null || cachedShorts.isEmpty) {
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    // Content loaded
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
        itemCount: cachedShorts.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator at end
          if (index == cachedShorts.length) {
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
            child: NewsCard(article: cachedShorts[index]),
          );
        },
      ),
    );
  }
}