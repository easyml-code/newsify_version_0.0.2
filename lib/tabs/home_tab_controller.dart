import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../data/shorts_data.dart';
import '../services/cache_manager.dart';

class HomeTabController {
  final TickerProvider vsync;
  final VoidCallback onUpdate;

  late TabController tabController;
  
  // Separate PageController for each category
  final Map<String, PageController> _pageControllers = {};
  final Map<String, int> _lastViewedPage = {};
  
  final CacheManager _cacheManager = CacheManager();
  
  bool isLoading = false;
  bool _isLoadingMore = false;
  String? errorMessage;
  final Map<String, int> _categoryOffsets = {};
  final int _pageSize = 20;
  final Map<String, bool> _categoryHasMoreData = {};

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

  HomeTabController({
    required this.vsync,
    required this.onUpdate,
  });

  String get currentCategory => categories[tabController.index];
  String? get currentCategoryFilter => _categoryMapping[currentCategory];
  
  // Get or create PageController for current category
  PageController get currentPageController {
    if (!_pageControllers.containsKey(currentCategory)) {
      // Always initialize with page 0, we'll jump to the correct page later
      _pageControllers[currentCategory] = PageController(initialPage: 0);
      _pageControllers[currentCategory]!.addListener(() => _onPageScroll(currentCategory));
    }
    return _pageControllers[currentCategory]!;
  }

  void initialize() {
    tabController = TabController(length: categories.length, vsync: vsync);
    
    // Initialize tracking for all categories
    for (var category in categories) {
      _categoryOffsets[category] = 0;
      _categoryHasMoreData[category] = true;
      _lastViewedPage[category] = 0;
    }
    
    // Listen to tab changes
    tabController.addListener(_onTabChanged);
    
    // Load initial data for Feed
    loadShortsForCurrentCategory();
  }

  void _onTabChanged() {
    if (!tabController.indexIsChanging) {
      debugPrint('📑 Tab changed to: $currentCategory (last page: ${_lastViewedPage[currentCategory]})');
      loadShortsForCurrentCategory();
      
      // Force rebuild to use correct PageController
      onUpdate();
      
      // Jump to last viewed page after the frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageControllers.containsKey(currentCategory)) {
          final lastPage = _lastViewedPage[currentCategory] ?? 0;
          final controller = _pageControllers[currentCategory]!;
          
          if (controller.hasClients && controller.page?.round() != lastPage) {
            controller.jumpToPage(lastPage);
            debugPrint('🔄 Jumped to page $lastPage for $currentCategory');
          }
        }
      });
    }
  }

  void _onPageScroll(String category) {
    final controller = _pageControllers[category];
    if (controller == null || !controller.hasClients) return;
    
    final cachedShorts = _cacheManager.getCachedShorts(category);
    if (cachedShorts == null) return;

    // Update last viewed page for this category
    final currentPage = controller.page?.round() ?? 0;
    _lastViewedPage[category] = currentPage;

    final maxScroll = controller.position.maxScrollExtent;
    final currentScroll = controller.position.pixels;
    final delta = maxScroll - currentScroll;

    // Load more when user is 3 items away from the end
    // Note: We need context for MediaQuery, so we'll use a fixed height estimate
    if (delta <= 3 * 800 && // Estimated screen height
        !_isLoadingMore &&
        (_categoryHasMoreData[category] ?? true) &&
        category == currentCategory) {
      loadMoreShorts();
    }
  }

  Future<void> loadShortsForCurrentCategory() async {
    // Check if we have cached data for this category
    if (_cacheManager.hasCachedShorts(currentCategory)) {
      debugPrint('✅ Using cached data for $currentCategory (${_cacheManager.getCachedShorts(currentCategory)!.length} items)');
      errorMessage = null;
      onUpdate();
      return;
    }

    // No cache, fetch from database
    isLoading = true;
    errorMessage = null;
    _categoryOffsets[currentCategory] = 0;
    _categoryHasMoreData[currentCategory] = true;
    onUpdate();

    try {
      final shorts = await fetchShorts(
        limit: _pageSize,
        offset: 0,
        category: currentCategoryFilter,
        randomizeOrder: true,
      );

      // Cache the fetched shorts
      _cacheManager.cacheShorts(currentCategory, shorts);
      _categoryOffsets[currentCategory] = shorts.length;
      
      isLoading = false;
      _categoryHasMoreData[currentCategory] = shorts.length >= _pageSize;
      onUpdate();
      
      debugPrint('✅ Loaded ${shorts.length} shorts for $currentCategory');
    } catch (e) {
      isLoading = false;
      errorMessage = 'Error loading news: $e';
      onUpdate();
      debugPrint('❌ Error loading shorts: $e');
    }
  }

  Future<void> loadMoreShorts() async {
    if (_isLoadingMore || !(_categoryHasMoreData[currentCategory] ?? true)) return;

    _isLoadingMore = true;
    onUpdate();

    try {
      final currentOffset = _categoryOffsets[currentCategory] ?? 0;
      
      final moreShorts = await fetchShorts(
        offset: currentOffset,
        limit: _pageSize,
        category: currentCategoryFilter,
        randomizeOrder: true,
      );

      if (moreShorts.isNotEmpty) {
        // Append to cache
        _cacheManager.appendShorts(currentCategory, moreShorts);
        _categoryOffsets[currentCategory] = currentOffset + moreShorts.length;
        _categoryHasMoreData[currentCategory] = moreShorts.length >= _pageSize;
      } else {
        _categoryHasMoreData[currentCategory] = false;
      }
      
      _isLoadingMore = false;
      onUpdate();
      
      debugPrint('✅ Loaded ${moreShorts.length} more shorts for $currentCategory');
    } catch (e) {
      _isLoadingMore = false;
      onUpdate();
      debugPrint('❌ Error loading more shorts: $e');
    }
  }

  Future<void> refreshShorts() async {
    // Clear cache for current category and reset scroll position
    _cacheManager.clearCategory(currentCategory);
    _categoryOffsets[currentCategory] = 0;
    _categoryHasMoreData[currentCategory] = true;
    _lastViewedPage[currentCategory] = 0;
    
    // Dispose old PageController and create new one
    if (_pageControllers.containsKey(currentCategory)) {
      _pageControllers[currentCategory]?.dispose();
      _pageControllers.remove(currentCategory);
    }
    
    await loadShortsForCurrentCategory();
  }

  // Helper methods for UI
  List<NewsArticle>? getCurrentCachedShorts() {
    return _cacheManager.getCachedShorts(currentCategory);
  }

  bool hasCachedShorts(String category) {
    return _cacheManager.hasCachedShorts(category);
  }

  bool categoryHasMoreData() {
    return _categoryHasMoreData[currentCategory] ?? true;
  }

  void dispose() {
    tabController.removeListener(_onTabChanged);
    tabController.dispose();
    
    // Dispose all PageControllers
    for (var controller in _pageControllers.values) {
      controller.dispose();
    }
    _pageControllers.clear();
  }
}