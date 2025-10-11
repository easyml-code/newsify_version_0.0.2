class NewsArticle {
  final String title;
  final String content;
  final String source;
  final String author;
  final String time;
  final String imageUrl;
  final String newsUrl;
  final String readMore;
  final String? location;

  NewsArticle({
    required this.title,
    required this.content,
    required this.source,
    required this.author,
    required this.time,
    required this.imageUrl,
    required this.newsUrl,
    required this.readMore,
    required this.location,
  });
}