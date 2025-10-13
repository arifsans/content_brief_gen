/// Abstract interface for AI providers (Anthropic Claude & Google Gemini)
/// This allows switching between different AI services seamlessly

enum AIProvider {
  anthropic,
  gemini,
}

/// Base class for AI-powered content brief generation
abstract class AIContentBriefGenerator {
  /// Generate a complete content brief
  Future<ContentBrief> generateContentBrief(
    String keyword,
    List<String> relatedKeywords,
  );
  
  /// Save content brief to files
  Future<void> saveContentBrief(ContentBrief brief, {String? timestampedFolder});
  
  /// Get performance metrics
  Map<String, dynamic> getMetrics();
  
  /// Print metrics summary
  void printMetrics();
  
  /// Cleanup resources
  void dispose();
}

/// Base class for AI-powered article title generation
abstract class AIArticleTitleGenerator {
  /// Generate SEO-friendly article titles from keyword list
  Future<List<String>> generateArticleTitles(List<String> keywords);
  
  /// Cleanup resources
  void dispose();
}

/// Base class for AI-powered full article generation
abstract class AIArticleGenerator {
  /// Generate a complete SEO-optimized article from content brief
  Future<String> generateArticle(ContentBrief brief);
  
  /// Save article to file
  Future<void> saveArticle(String article, String keyword, {String? timestampedFolder});
  
  /// Get performance metrics
  Map<String, dynamic> getMetrics();
  
  /// Print metrics summary
  void printMetrics();
  
  /// Cleanup resources
  void dispose();
}

/// Content Brief data model (shared across all providers)
class ContentBrief {
  final String keyword;
  final String topic;
  final String title;
  final String metaDescription;
  final List<String> articleStructure;
  final List<String> relatedKeywords;
  final DateTime generatedAt;
  final String provider; // Track which AI provider generated this

  ContentBrief({
    required this.keyword,
    required this.topic,
    required this.title,
    required this.metaDescription,
    required this.articleStructure,
    required this.relatedKeywords,
    required this.generatedAt,
    this.provider = 'unknown',
  });

  Map<String, dynamic> toJson() => {
    'keyword': keyword,
    'topic': topic,
    'title': title,
    'meta_description': metaDescription,
    'article_structure': articleStructure,
    'related_keywords': relatedKeywords,
    'generated_at': generatedAt.toIso8601String(),
    'ai_provider': provider,
  };
  
  /// Format brief as readable text
  String toFormattedText() {
    return '''
═══════════════════════════════════════════════════════════════
                    SEO CONTENT BRIEF
═══════════════════════════════════════════════════════════════

Generated: ${generatedAt.toLocal().toString().split('.')[0]}
Generator: ${provider.toUpperCase()} AI
Version: 3.0

───────────────────────────────────────────────────────────────
PRIMARY KEYWORD
───────────────────────────────────────────────────────────────
$keyword

───────────────────────────────────────────────────────────────
TOPIK BLOG
───────────────────────────────────────────────────────────────
$topic

───────────────────────────────────────────────────────────────
JUDUL H1
───────────────────────────────────────────────────────────────
$title

Character count: ${title.length}
Optimal: ${title.length >= 50 && title.length <= 60 ? '✅' : '⚠️ ${title.length < 50 ? 'Terlalu pendek' : 'Terlalu panjang'}'}

───────────────────────────────────────────────────────────────
META DESCRIPTION
───────────────────────────────────────────────────────────────
$metaDescription

Character count: ${metaDescription.length}
Optimal: ${metaDescription.length >= 150 && metaDescription.length <= 160 ? '✅' : '⚠️ ${metaDescription.length < 150 ? 'Terlalu pendek' : 'Terlalu panjang'}'}

───────────────────────────────────────────────────────────────
STRUKTUR ARTIKEL (${articleStructure.length} Headings)
───────────────────────────────────────────────────────────────
${articleStructure.asMap().entries.map((e) => '${e.value}').join('\n')}

───────────────────────────────────────────────────────────────
RELATED KEYWORDS (Top 10)
───────────────────────────────────────────────────────────────
${relatedKeywords.take(10).toList().asMap().entries.map((e) => '${e.value}').join('\n')}

═══════════════════════════════════════════════════════════════
                        END OF BRIEF
═══════════════════════════════════════════════════════════════
''';
  }
}
