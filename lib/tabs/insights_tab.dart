import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/insights_service.dart';
import '../models/news_article.dart';
import '../widgets/insights_news_item.dart';
import '../widgets/search_results_view.dart';

class InsightsTab extends StatefulWidget {
  const InsightsTab({super.key});

  @override
  State<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends State<InsightsTab> with AutomaticKeepAliveClientMixin {
  final InsightsService _insightsService = InsightsService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isSearching = false;
  bool _isLoadingNotifications = false;
  List<NewsArticle> _notifications = [];
  String? _errorMessage;
  
  String _selectedCategory = 'my_feed';
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoadingNotifications = true;
      _errorMessage = null;
    });

    try {
      final notifications = await _insightsService.fetchLatestNews(
        limit: 3,
        forceRefresh: false, // Use cache if available
      );
      setState(() {
        _notifications = notifications;
        _isLoadingNotifications = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingNotifications = false;
      });
    }
  }

  void _handleSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() => _isSearching = false);
      return;
    }

    setState(() => _isSearching = true);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _isSearching = false);
  }

  void _handleCategorySelect(String category) {
    setState(() => _selectedCategory = category);
    
    // Navigate to category view
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryNewsView(
          category: category,
          categoryName: _getCategoryName(category),
        ),
      ),
    );
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'my_feed':
        return 'My Feed';
      case 'all_news':
        return 'All News';
      case 'top_stories':
        return 'Top Stories';
      case 'trending':
        return 'Trending';
      default:
        return 'News';
    }
  }

  void _viewAllNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AllNotificationsView(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDarkMode = themeProvider.isDarkMode;
        
        return Scaffold(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                _buildSearchBar(isDarkMode),
                Expanded(
                  child: _isSearching
                      ? SearchResultsView(
                          searchQuery: _searchController.text,
                          onClose: _clearSearch,
                        )
                      : _buildMainContent(isDarkMode),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: _isSearching
            ? Border.all(color: const Color(0xFF2196F3), width: 2)
            : null,
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Search for News, Topics',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                  fontSize: 16,
                ),
                border: InputBorder.none,
              ),
              onChanged: _handleSearch,
              onSubmitted: _handleSearch,
            ),
          ),
          if (_isSearching)
            IconButton(
              icon: Icon(
                Icons.close,
                color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                size: 20,
              ),
              onPressed: _clearSearch,
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isDarkMode) {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: const Color(0xFF2196F3),
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Icons
            _buildCategoryIcons(isDarkMode),
            const SizedBox(height: 30),
            
            // Notifications Section
            _buildNotificationsSection(isDarkMode),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcons(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCategoryIcon(
            Icons.rss_feed,
            'My Feed',
            'my_feed',
            _selectedCategory == 'my_feed',
            isDarkMode,
          ),
          _buildCategoryIcon(
            Icons.list_alt,
            'All News',
            'all_news',
            _selectedCategory == 'all_news',
            isDarkMode,
          ),
          _buildCategoryIcon(
            Icons.star,
            'Top Stories',
            'top_stories',
            _selectedCategory == 'top_stories',
            isDarkMode,
          ),
          _buildCategoryIcon(
            Icons.local_fire_department,
            'Trending',
            'trending',
            _selectedCategory == 'trending',
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(
    IconData icon,
    String label,
    String category,
    bool isSelected,
    bool isDarkMode,
  ) {
    return GestureDetector(
      onTap: () => _handleCategorySelect(category),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2196F3)
                  : (isDarkMode ? Colors.grey[900] : Colors.grey[200]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (isDarkMode ? Colors.grey[600] : Colors.grey[600]),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF2196F3)
                  : (isDarkMode ? Colors.grey[600] : Colors.grey[700]),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection(bool isDarkMode) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest News',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _viewAllNotifications,
                child: const Text(
                  'VIEW ALL',
                  style: TextStyle(
                    color: Color(0xFF2196F3),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        if (_isLoadingNotifications)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF2196F3),
              ),
            ),
          )
        else if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load news',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadNotifications,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else if (_notifications.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Text(
                'No news available',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ..._notifications.map((article) => InsightsNewsItem(
                article: article,
                isDarkMode: isDarkMode,
              )),
      ],
    );
  }
}

// Category News View
class CategoryNewsView extends StatefulWidget {
  final String category;
  final String categoryName;

  const CategoryNewsView({
    super.key,
    required this.category,
    required this.categoryName,
  });

  @override
  State<CategoryNewsView> createState() => _CategoryNewsViewState();
}

class _CategoryNewsViewState extends State<CategoryNewsView> {
  final InsightsService _insightsService = InsightsService();
  final ScrollController _scrollController = ScrollController();
  
  List<NewsArticle> _news = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreNews();
      }
    }
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final news = await _insightsService.fetchCategoryNews(
        category: widget.category,
        limit: _limit,
        offset: 0,
        forceRefresh: false, // Use cache if available
      );
      
      setState(() {
        _news = news;
        _offset = news.length;
        _hasMore = news.length >= _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreNews() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final moreNews = await _insightsService.fetchCategoryNews(
        category: widget.category,
        limit: _limit,
        offset: _offset,
      );
      
      setState(() {
        _news.addAll(moreNews);
        _offset += moreNews.length;
        _hasMore = moreNews.length >= _limit;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      debugPrint('Error loading more: $e');
    }
  }

  Future<void> _refreshNews() async {
    // Clear cache and force refresh
    _insightsService.clearCategoryCache(widget.category);
    
    setState(() {
      _offset = 0;
      _hasMore = true;
    });
    await _loadNews();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDarkMode = themeProvider.isDarkMode;
        
        return Scaffold(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          appBar: AppBar(
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.categoryName,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: _buildBody(isDarkMode),
        );
      },
    );
  }

  Widget _buildBody(bool isDarkMode) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2196F3),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load news',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNews,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_news.isEmpty) {
      return Center(
        child: Text(
          'No news available',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
            fontSize: 16,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshNews,
      color: const Color(0xFF2196F3),
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: _news.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _news.length) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFF2196F3),
                ),
              ),
            );
          }
          
          return InsightsNewsItem(
            article: _news[index],
            isDarkMode: isDarkMode,
          );
        },
      ),
    );
  }
}

// All Notifications View
class AllNotificationsView extends StatefulWidget {
  const AllNotificationsView({super.key});

  @override
  State<AllNotificationsView> createState() => _AllNotificationsViewState();
}

class _AllNotificationsViewState extends State<AllNotificationsView> {
  final InsightsService _insightsService = InsightsService();
  final ScrollController _scrollController = ScrollController();
  
  List<NewsArticle> _news = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreNews();
      }
    }
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final news = await _insightsService.fetchLatestNews(
        limit: _limit,
        offset: 0,
        forceRefresh: false, // Use cache if available
      );
      
      setState(() {
        _news = news;
        _offset = news.length;
        _hasMore = news.length >= _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreNews() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final moreNews = await _insightsService.fetchLatestNews(
        limit: _limit,
        offset: _offset,
      );
      
      setState(() {
        _news.addAll(moreNews);
        _offset += moreNews.length;
        _hasMore = moreNews.length >= _limit;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      debugPrint('Error loading more: $e');
    }
  }

  Future<void> _refreshNews() async {
    setState(() {
      _offset = 0;
      _hasMore = true;
    });
    await _loadNews();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDarkMode = themeProvider.isDarkMode;
        
        return Scaffold(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          appBar: AppBar(
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'All Latest News',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: _buildBody(isDarkMode),
        );
      },
    );
  }

  Widget _buildBody(bool isDarkMode) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2196F3),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load news',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNews,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_news.isEmpty) {
      return Center(
        child: Text(
          'No news available',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
            fontSize: 16,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshNews,
      color: const Color(0xFF2196F3),
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: _news.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _news.length) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFF2196F3),
                ),
              ),
            );
          }
          
          return InsightsNewsItem(
            article: _news[index],
            isDarkMode: isDarkMode,
          );
        },
      ),
    );
  }
}