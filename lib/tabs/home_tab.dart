import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../widgets/news_card.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLocalSelected = false;

  final List<String> categories = [
    'Feed',
    'Finance',
    'Timelines',
    'Videos',
    'Insights'
  ];

  // Sample news articles
  final List<NewsArticle> newsArticles = [
    NewsArticle(
      title: "The day Yuvraj hands his kids to me, they'll meet same fate as he did: Yograj",
      content: "Ex-cricketer Yograj Singh said the day his son Yuvraj Singh hands his children over to him, they'll meet the same fate as Yuvraj did. \"You can only forge gold through fire. There'll be no mercy...That's what they fear, and that's why we aren't together,\" he added. Yograj said he first met Yuvraj's son Orion when he was two years old.",
      source: 'Indian Express',
      author: 'Bhawana Chaudhary',
      time: 'few hours ago',
      imageUrl: 'https://images.indianexpress.com/2025/10/Delhi-cops-2.jpg',
      newsUrl: 'https://indianexpress.com/article/cities/delhi/accused-of-doctors-murder-robberies-nepali-killed-in-encounter-10292287/',
      readMore: "Test",
    ),
    NewsArticle(
      title: "White House responds as Trump doesn't win Nobel, says 'He'll continue saving lives'",
      content: "The White House has responded after Donald Trump didn't win the Nobel Peace Prize 2025. A spokesperson said Trump will continue his work of saving lives and promoting peace globally.",
      source: 'Reuters',
      author: 'John Smith',
      time: '2 hours ago',
      imageUrl: 'https://example.com/trump.jpg',
      newsUrl: 'https://reuters.com/world/us',
      readMore: "Test",
    ),
    NewsArticle(
      title: "Gaza ceasefire comes into effect, says Israel",
      content: "Israel announced that the Gaza ceasefire has officially come into effect. The ceasefire was brokered after weeks of negotiations and is expected to bring temporary relief to the region.",
      source: 'BBC',
      author: 'Sarah Johnson',
      time: '3 hours ago',
      imageUrl: 'https://example.com/gaza.jpg',
      newsUrl: 'https://bbc.com/news/world-middle-east',
      readMore: "Test",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _local() {
    setState(() {
      _isLocalSelected = !_isLocalSelected;
    });
    debugPrint('Local button clicked - Selected: $_isLocalSelected');
    // Add your local news filtering logic here
  }

  @override
  Widget build(BuildContext context) {
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
                        padding: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
                        child: GestureDetector(
                          onTap: _local,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: _isLocalSelected 
                                  ? const Color(0xFF2196F3).withOpacity(0.15)
                                  : Colors.grey[900],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isLocalSelected 
                                    ? const Color(0xFF2196F3)
                                    : Colors.grey[800]!,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Local',
                              style: TextStyle(
                                color: _isLocalSelected 
                                    ? const Color(0xFF2196F3)
                                    : Colors.grey[400],
                                fontSize: 14,
                                fontWeight: _isLocalSelected 
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
                          labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          tabAlignment: TabAlignment.start,
                          padding: EdgeInsets.zero,
                          tabs: categories.map((category) => Text(category)).toList(),
                        ),
                      ),
                    ],
                  ),
                  // Gradient fade effect on the left side of scrollable tabs
                  Positioned(
                    left: 80, // Position after Local button
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
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: newsArticles.length,
                itemBuilder: (context, index) {
                  return Transform.translate(
                    offset: const Offset(0, -10),
                    child: NewsCard(article: newsArticles[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}