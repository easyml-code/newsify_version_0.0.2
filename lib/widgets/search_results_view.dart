import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/insights_service.dart';
import '../models/news_article.dart';
import 'insights_news_item.dart';

/// Search results view with real-time search
/// Shows suggestions and results as user types
class SearchResultsView extends StatefulWidget {
  final String searchQuery;
  final VoidCallback onClose;

  const SearchResultsView({
    super.key,
    required this.searchQuery,
    required this.onClose,
  });

  @override
  State<SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends State<SearchResultsView> {
  final InsightsService _insightsService = InsightsService();
  final ScrollController _scrollController = ScrollController();
  
  List<NewsArticle> _results = [];
  List<String> _suggestions = [];
  bool _isSearching = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 10;
  String? _errorMessage;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.searchQuery;
    _performSearch();
    _loadSuggestions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(SearchResultsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _currentQuery = widget.searchQuery;
      _resetAndSearch();
      _loadSuggestions();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore && _results.isNotEmpty) {
        _loadMoreResults();
      }
    }
  }

  Future<void> _resetAndSearch() async {
    setState(() {
      _offset = 0;
      _hasMore = true;
      _results = [];
    });
    await _performSearch();
  }

  Future<void> _performSearch() async {
    if (_currentQuery.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final results = await _insightsService.searchNews(
        query: _currentQuery,
        limit: _limit,
        offset: 0,
      );
      
      if (mounted) {
        setState(() {
          _results = results;
          _offset = results.length;
          _hasMore = results.length >= _limit;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _loadMoreResults() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final moreResults = await _insightsService.searchNews(
        query: _currentQuery,
        limit: _limit,
        offset: _offset,
      );
      
      if (mounted) {
        setState(() {
          _results.addAll(moreResults);
          _offset += moreResults.length;
          _hasMore = moreResults.length >= _limit;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
      debugPrint('Error loading more results: $e');
    }
  }

  Future<void> _loadSuggestions() async {
    if (_currentQuery.trim().isEmpty || _currentQuery.length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    try {
      final suggestions = await _insightsService.getSearchSuggestions(_currentQuery);
      if (mounted) {
        setState(() => _suggestions = suggestions);
      }
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDarkMode = themeProvider.isDarkMode;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search header
            if (_suggestions.isNotEmpty && _results.isEmpty && !_isSearching)
              _buildSuggestionsSection(isDarkMode),
            
            // Results count or status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildSearchStatus(isDarkMode),
            ),
            
            // Results list
            Expanded(
              child: _buildResultsList(isDarkMode),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSuggestionsSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggestions',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.take(5).map((suggestion) {
              return GestureDetector(
                onTap: () {
                  // Trigger new search with suggestion
                  setState(() {
                    _currentQuery = suggestion;
                  });
                  _resetAndSearch();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search,
                        size: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          suggestion,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchStatus(bool isDarkMode) {
    if (_isSearching) {
      return Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: const Color(0xFF2196F3),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Searching...',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: Colors.red[400],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Search failed',
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: _performSearch,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (_results.isEmpty) {
      return Text(
        'No results found for "$_currentQuery"',
        style: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          fontSize: 14,
        ),
      );
    }

    return Text(
      '${_results.length} result${_results.length != 1 ? 's' : ''} for "$_currentQuery"',
      style: TextStyle(
        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildResultsList(bool isDarkMode) {
    if (_isSearching && _results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF2196F3),
            ),
            const SizedBox(height: 16),
            Text(
              'Searching for "$_currentQuery"',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _results.isEmpty) {
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
              'Search failed',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 60,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: _results.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _results.length) {
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
          article: _results[index],
          isDarkMode: isDarkMode,
        );
      },
    );
  }
}