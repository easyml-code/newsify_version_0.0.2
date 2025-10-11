import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../widgets/news_card.dart';
import 'home_tab_controller.dart';

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
  
  HomeTabController? _controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = HomeTabController(
      vsync: this,
      onUpdate: () {
        if (mounted) setState(() {});
      },
    );
    _controller!.initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // Safety check - return loading if controller not ready
    if (_controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2196F3),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Row(
            children: [
              _buildLocalButton(),
              const SizedBox(width: 8),
              _buildCategoryTabs(),
            ],
          ),
          _buildGradientFade(),
        ],
      ),
    );
  }

  Widget _buildLocalButton() {
    return Padding(
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
    );
  }

  Widget _buildCategoryTabs() {
    return Expanded(
      child: TabBar(
        controller: _controller!.tabController,
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
        tabs: _controller!.categories.map((category) {
          final hasCached = _controller!.hasCachedShorts(category);
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
    );
  }

  Widget _buildGradientFade() {
    return Positioned(
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
    );
  }

  Widget _buildContent() {
    final cachedShorts = _controller!.getCurrentCachedShorts();

    // Initial loading
    if (_controller!.isLoading && cachedShorts == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2196F3),
        ),
      );
    }

    // Error state
    if (_controller!.errorMessage != null && cachedShorts == null) {
      return _buildErrorState();
    }

    // Empty state
    if (cachedShorts == null || cachedShorts.isEmpty) {
      return _buildEmptyState();
    }

    // Content loaded
    return _buildNewsCards(cachedShorts);
  }

  Widget _buildErrorState() {
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
              _controller!.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _controller!.loadShortsForCurrentCategory,
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

  Widget _buildEmptyState() {
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
            onPressed: _controller!.refreshShorts,
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

  Widget _buildNewsCards(List<NewsArticle> cachedShorts) {
    return RefreshIndicator(
      onRefresh: _controller!.refreshShorts,
      color: const Color(0xFF2196F3),
      backgroundColor: Colors.grey[900],
      child: PageView.builder(
        key: ValueKey(_controller!.currentCategory),
        controller: _controller!.currentPageController,
        scrollDirection: Axis.vertical,
        itemCount: cachedShorts.length + 
            (_controller!.categoryHasMoreData() ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator at end
          if (index == cachedShorts.length) {
            return _buildLoadingIndicator();
          }

          return Transform.translate(
            offset: const Offset(0, -10),
            child: NewsCard(article: cachedShorts[index]),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
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
}