import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../data/shorts_data.dart';
import '../services/cache_manager.dart';

class HomeTabController {
  final TickerProvider vsync;
  final VoidCallback onUpdate;

  late TabController tabController;
  
  final Map<String, PageController> _pageControllers = {};
  final Map<String, int> _lastViewedPage = {};
  
  final CacheManager _cacheManager = CacheManager();
  
  bool isLoading = false;
  bool _isLoadingMore = false;
  String? errorMessage;
  final Map<String, int> _categoryOffsets = {};
  final int _pageSize = 20;
  final Map<String, bool> _categoryHasMoreData = {};

  // Location filter
  bool _isLocalFilter = false;
  String? _userDistrict;

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
  
  // Generate cache key based on category and location filter
  String _getCacheKey(String category) {
    return _isLocalFilter && _userDistrict != null
        ? '${category}_local_$_userDistrict'
        : category;
  }

  PageController get currentPageController {
    final cacheKey = _getCacheKey(currentCategory);
    if (!_pageControllers.containsKey(cacheKey)) {
      _pageControllers[cacheKey] = PageController(initialPage: 0);
      _pageControllers[cacheKey]!.addListener(() => _onPageScroll(cacheKey));
    }
    return _pageControllers[cacheKey]!;
  }


  void initialize() {
    tabController = TabController(length: categories.length, vsync: vsync);
    
    for (var category in categories) {
      _categoryOffsets[category] = 0;
      _categoryHasMoreData[category] = true;
      _lastViewedPage[category] = 0;
    }
    
    tabController.addListener(_onTabChanged);
    loadShortsForCurrentCategory();
  }

  void updateLocationFilter(bool isLocal, String? district) {
    final oldLocalState = _isLocalFilter;
    final oldDistrict = _userDistrict;

    _isLocalFilter = isLocal;
    _userDistrict = district;

    // Only reload if filter actually changed
    if (oldLocalState != isLocal || oldDistrict != district) {
      debugPrint('🔄 Location filter changed. Local: $isLocal, District: $district');
      
      // Reset all categories
      for (var category in categories) {
        _categoryOffsets[category] = 0;
        _categoryHasMoreData[category] = true;
        _lastViewedPage[category] = 0;
      }
      
      // Reload current category
      loadShortsForCurrentCategory();
    }
  }

  void _onTabChanged() {
    if (!tabController.indexIsChanging) {
      final cacheKey = _getCacheKey(currentCategory);
      debugPrint('📑 Tab changed to: $currentCategory (cache: $cacheKey, last page: ${_lastViewedPage[cacheKey]})');
      loadShortsForCurrentCategory();
      
      onUpdate();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageControllers.containsKey(cacheKey)) {
          final lastPage = _lastViewedPage[cacheKey] ?? 0;
          final controller = _pageControllers[cacheKey]!;
          
          if (controller.hasClients && controller.page?.round() != lastPage) {
            controller.jumpToPage(lastPage);
            debugPrint('🔄 Jumped to page $lastPage for $cacheKey');
          }
        }
      });
    }
  }

  void _onPageScroll(String cacheKey) {
    final controller = _pageControllers[cacheKey];
    if (controller == null || !controller.hasClients) return;
    
    final cachedShorts = _cacheManager.getCachedShorts(cacheKey);
    if (cachedShorts == null) return;

    final currentPage = controller.page?.round() ?? 0;
    _lastViewedPage[cacheKey] = currentPage;

    final maxScroll = controller.position.maxScrollExtent;
    final currentScroll = controller.position.pixels;
    final delta = maxScroll - currentScroll;

    if (delta <= 3 * 800 &&
        !_isLoadingMore &&
        (_categoryHasMoreData[currentCategory] ?? true) &&
        cacheKey == _getCacheKey(currentCategory)) {
      loadMoreShorts();
    }
  }

  Future<void> loadShortsForCurrentCategory() async {
    final cacheKey = _getCacheKey(currentCategory);
    
    // Check cache staleness
    if (_cacheManager.hasCachedShorts(cacheKey)) {
      if (_cacheManager.isCacheStale(cacheKey, const Duration(minutes: 5))) {
        debugPrint('⚠️ Cache is stale for $cacheKey, refreshing...');
        _cacheManager.clearCategory(cacheKey);
      } else {
        debugPrint('✅ Using cached data for $cacheKey (${_cacheManager.getCachedShorts(cacheKey)!.length} items)');
        errorMessage = null;
        onUpdate();
        return;
      }
    }

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
        locationFilter: _isLocalFilter ? _userDistrict : null,
      );

      _cacheManager.cacheShorts(cacheKey, shorts);
      _categoryOffsets[currentCategory] = shorts.length;
      
      isLoading = false;
      _categoryHasMoreData[currentCategory] = shorts.length >= _pageSize;
      onUpdate();
      
      debugPrint('✅ Loaded ${shorts.length} shorts for $cacheKey');
    } catch (e) {
      isLoading = false;
      errorMessage = 'Error loading news: $e';
      onUpdate();
      debugPrint('❌ Error loading shorts: $e');
    }
  }

  Future<void> loadMoreShorts() async {
    if (_isLoadingMore || !(_categoryHasMoreData[currentCategory] ?? true)) return;

    final cacheKey = _getCacheKey(currentCategory);
    _isLoadingMore = true;
    onUpdate();

    try {
      final currentOffset = _categoryOffsets[currentCategory] ?? 0;
      
      final moreShorts = await fetchShorts(
        offset: currentOffset,
        limit: _pageSize,
        category: currentCategoryFilter,
        randomizeOrder: true,
        locationFilter: _isLocalFilter ? _userDistrict : null,
      );

      if (moreShorts.isNotEmpty) {
        _cacheManager.appendShorts(cacheKey, moreShorts);
        _categoryOffsets[currentCategory] = currentOffset + moreShorts.length;
        _categoryHasMoreData[currentCategory] = moreShorts.length >= _pageSize;
      } else {
        _categoryHasMoreData[currentCategory] = false;
      }
      
      _isLoadingMore = false;
      onUpdate();
      
      debugPrint('✅ Loaded ${moreShorts.length} more shorts for $cacheKey');
    } catch (e) {
      _isLoadingMore = false;
      onUpdate();
      debugPrint('❌ Error loading more shorts: $e');
    }
  }

  Future<void> refreshShorts() async {
    final cacheKey = _getCacheKey(currentCategory);
    _cacheManager.clearCategory(cacheKey);
    _categoryOffsets[currentCategory] = 0;
    _categoryHasMoreData[currentCategory] = true;
    _lastViewedPage[cacheKey] = 0;
    
    if (_pageControllers.containsKey(cacheKey)) {
      _pageControllers[cacheKey]?.dispose();
      _pageControllers.remove(cacheKey);
    }
    
    await loadShortsForCurrentCategory();
  }

  List<NewsArticle>? getCurrentCachedShorts() {
    final cacheKey = _getCacheKey(currentCategory);
    return _cacheManager.getCachedShorts(cacheKey);
  }

  bool hasCachedShorts(String category) {
    final cacheKey = _getCacheKey(category);
    return _cacheManager.hasCachedShorts(cacheKey);
  }

  bool categoryHasMoreData() {
    return _categoryHasMoreData[currentCategory] ?? true;
  }

  void dispose() {
    tabController.removeListener(_onTabChanged);
    tabController.dispose();
    
    for (var controller in _pageControllers.values) {
      controller.dispose();
    }
    _pageControllers.clear();
  }
}