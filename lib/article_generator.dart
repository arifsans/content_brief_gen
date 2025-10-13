import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';
import 'package:content_brief_gen/word_document_generator.dart';
import 'ai_provider.dart';

/// Configuration for article generation
class ArticleConfig {
  static const int maxTokens = 6000; // Reduced to limit article length (~2000 words)
  static const int maxRetries = 3;
  static const Duration initialRetryDelay = Duration(seconds: 2);
  static const Duration maxTimeout = Duration(minutes: 10);
  static const Duration minRequestDelay = Duration(milliseconds: 500);
}

/// Metrics collector for article generation
class ArticleMetricsCollector {
  int totalRequests = 0;
  int successfulRequests = 0;
  int failedRequests = 0;
  double totalCostUSD = 0.0;
  List<int> latenciesMs = [];
  int totalInputTokens = 0;
  int totalOutputTokens = 0;
  int totalCacheReadTokens = 0;
  
  void recordRequest({
    required bool success,
    required int latencyMs,
    required int inputTokens,
    required int outputTokens,
    int? cacheReadTokens,
  }) {
    totalRequests++;
    if (success) {
      successfulRequests++;
    } else {
      failedRequests++;
    }
    
    latenciesMs.add(latencyMs);
    totalInputTokens += inputTokens;
    totalOutputTokens += outputTokens;
    if (cacheReadTokens != null) {
      totalCacheReadTokens += cacheReadTokens;
    }
    
    // Calculate cost (Claude Sonnet 4 pricing)
    final inputCost = inputTokens * 0.003 / 1000;
    final outputCost = outputTokens * 0.015 / 1000;
    final cacheCost = (cacheReadTokens ?? 0) * 0.0003 / 1000;
    totalCostUSD += inputCost + outputCost + cacheCost;
  }
  
  double getAverageLatency() {
    if (latenciesMs.isEmpty) return 0.0;
    return latenciesMs.reduce((a, b) => a + b) / latenciesMs.length;
  }
  
  double getSuccessRate() {
    if (totalRequests == 0) return 0.0;
    return (successfulRequests / totalRequests) * 100;
  }
}

/// Article Generator using Anthropic Claude API
class ArticleGenerator implements AIArticleGenerator {
  final String apiKey;
  final AnthropicClient _client;
  final ArticleMetricsCollector _metrics = ArticleMetricsCollector();
  DateTime? _lastRequestTime;

  ArticleGenerator({required this.apiKey})
      : _client = AnthropicClient(apiKey: apiKey);

  @override
  Future<String> generateArticle(ContentBrief brief) async {
    print('📝 Generating full SEO-optimized article for: "${brief.keyword}"');
    print('   Using AI: Anthropic Claude Sonnet 4');
    print('   Structure: ${brief.articleStructure.length} sections\n');

    final startTime = DateTime.now();

    try {
      // Rate limiting
      await _enforceRateLimit();

      // Build comprehensive prompt for article generation
      final prompt = _buildArticlePrompt(brief);

      // Make API call with retry logic
      final article = await _generateWithRetry(prompt);

      final latency = DateTime.now().difference(startTime).inMilliseconds;
      print('✅ Article generated successfully in ${latency}ms');
      print('   Word count: ~${article.split(' ').length} words\n');

      return article;
    } catch (e) {
      print('❌ Error generating article: $e');
      rethrow;
    }
  }

  String _buildArticlePrompt(ContentBrief brief) {
    return '''You are an expert SEO content writer specializing in creating high-quality, engaging articles that rank on page one of Google search results.

Your task is to write a COMPLETE, COMPREHENSIVE, and SEO-OPTIMIZED article based on the following content brief:

PRIMARY KEYWORD: ${brief.keyword}

TOPIC: ${brief.topic}

H1 TITLE: ${brief.title}

META DESCRIPTION: ${brief.metaDescription}

ARTICLE STRUCTURE (Follow this exactly):
${brief.articleStructure.join('\n')}

RELATED KEYWORDS TO INCLUDE:
${brief.relatedKeywords.take(15).join(', ')}

CRITICAL LENGTH REQUIREMENT:
- STRICT MAXIMUM: 2000 words (DO NOT EXCEED THIS)
- MINIMUM: 1000 words
- Target: 1500-1800 words for optimal balance
- Count your words carefully and stop when approaching 2000 words

WRITING REQUIREMENTS:
1. Write in Bahasa Indonesia (natural, conversational, engaging style)
2. Article length: STRICT 1000-2000 words (monitor word count throughout)
3. Use the exact heading structure provided (H1, H2, H3)
4. Include the primary keyword naturally throughout (aim for 1-2% density)
5. Incorporate related keywords naturally
6. Write engaging introductions that hook readers (100-150 words)
7. Use short paragraphs (2-4 sentences max)
8. Include actionable tips and practical advice
9. End with a strong conclusion that summarizes key points (100-150 words)
10. Use transition words for better flow
11. Write in second person when appropriate (using "Kamu")
12. Include examples and scenarios where relevant
13. Be CONCISE - quality over quantity, respect the word limit

SEO OPTIMIZATION REQUIREMENTS:
- Front-load important keywords in the introduction
- Use keyword variations naturally
- Write compelling, benefit-driven content
- Ensure readability (aim for grade 8 reading level)
- Use bullet points and numbered lists where appropriate
- Make each section valuable and informative

CONTENT QUALITY:
- Be authoritative and trustworthy
- Provide accurate, up-to-date information
- Write original content (no plagiarism)
- Be comprehensive but concise - cover the topic thoroughly within word limits
- Answer user intent completely
- Use E-E-A-T principles (Experience, Expertise, Authoritativeness, Trustworthiness)

FORMAT:
- Start directly with the H1 title (# Title)
- Follow with engaging introduction (100-150 words)
- Use the exact heading structure provided
- Write focused content under each heading (150-250 words per section to stay within limits)
- End with a comprehensive conclusion (100-150 words)
- After conclusion, add a natural "## Referensi dan Sumber Terpercaya" section

SOURCES SECTION (SEO-FRIENDLY):
After the conclusion, add a "## Referensi dan Sumber Terpercaya" section:
- Write 2-3 SHORT paragraphs (50-80 words total) mentioning the credible sources
- Make it conversational and natural, NOT a list format
- Weave source mentions naturally into sentences
- Use phrases like "Informasi dalam artikel ini merujuk pada...", "Data dikumpulkan dari berbagai sumber terpercaya seperti...", "Kami mengacu pada panduan dari..."
- Mention 3-5 authoritative sources naturally (government agencies, research institutions, expert publications, industry leaders)
- Keep it brief, engaging, and SEO-friendly
- Example style: "Informasi dalam artikel ini dikumpulkan dari berbagai sumber terpercaya, termasuk Kementerian Kesehatan RI, WHO (World Health Organization), dan jurnal kesehatan internasional. Semua data telah diverifikasi untuk memastikan akurasi dan relevansi dengan kebutuhan pembaca di Indonesia."

Please write the complete article now. Make it engaging, informative, optimized for ranking, and STRICTLY within 1000-2000 words including the sources section.''';
  }

  Future<String> _generateWithRetry(String prompt) async {
    int attempt = 0;
    Duration delay = ArticleConfig.initialRetryDelay;

    while (attempt < ArticleConfig.maxRetries) {
      attempt++;
      
      try {
        print('   → API call attempt $attempt/${ArticleConfig.maxRetries}...');
        
        final response = await _client
            .createMessage(
              request: CreateMessageRequest(
                model: Model.modelId('claude-sonnet-4-5-20250929'),
                maxTokens: ArticleConfig.maxTokens,
                messages: [
                  Message(
                    role: MessageRole.user,
                    content: MessageContent.text(prompt),
                  ),
                ],
              ),
            )
            .timeout(ArticleConfig.maxTimeout);

        // Extract usage stats
        final usage = response.usage;
        final inputTokens = usage?.inputTokens ?? 0;
        final outputTokens = usage?.outputTokens ?? 0;
        final cacheReadTokens = usage?.cacheReadInputTokens ?? 0;

        // Record metrics
        _metrics.recordRequest(
          success: true,
          latencyMs: DateTime.now().millisecondsSinceEpoch,
          inputTokens: inputTokens,
          outputTokens: outputTokens,
          cacheReadTokens: cacheReadTokens,
        );

        // Extract article text using the text getter
        final articleText = response.content.text;
        
        if (articleText.isEmpty) {
          throw Exception('Empty response from API');
        }

        return articleText;
        
      } catch (e) {
        print('   ⚠️ Attempt $attempt failed: $e');
        
        _metrics.recordRequest(
          success: false,
          latencyMs: 0,
          inputTokens: 0,
          outputTokens: 0,
        );

        if (attempt >= ArticleConfig.maxRetries) {
          print('   ❌ All retry attempts exhausted');
          rethrow;
        }

        print('   ⏳ Retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }

    throw Exception('Failed after ${ArticleConfig.maxRetries} attempts');
  }

  Future<void> _enforceRateLimit() async {
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < ArticleConfig.minRequestDelay) {
        final waitTime = ArticleConfig.minRequestDelay - elapsed;
        await Future.delayed(waitTime);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  @override
  Future<void> saveArticle(String article, String keyword, {String? timestampedFolder}) async {
    final baseDir = timestampedFolder != null ? 'results/$timestampedFolder' : 'results/article';
    final resultsDir = Directory(baseDir);
    await resultsDir.create(recursive: true);

    final safeFilename = keyword
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .toLowerCase();

    // Save as Markdown
    final mdFile = File('${resultsDir.path}/${safeFilename}_article.md');
    await mdFile.writeAsString(article);
    print('💾 Markdown saved: ${mdFile.path}');

    //Save as Word Document
    final docGenerator = WordDocumentGenerator();
    try {
      await docGenerator.generateArticleWordDocument(article, keyword, timestampedFolder: timestampedFolder);
    } catch (e) {
      print('   ❌ Failed to save Word Document: $e');
    }

    // Save metadata
    final metadata = {
      'keyword': keyword,
      'generated_at': DateTime.now().toIso8601String(),
      'ai_provider': 'anthropic_claude',
      'model': 'claude-sonnet-4-5-20250929',
      'word_count': article.split(' ').length,
      'character_count': article.length,
    };

    final metadataFile = File('${resultsDir.path}/${safeFilename}_article_metadata.json');
    await metadataFile.writeAsString(
      JsonEncoder.withIndent('  ').convert(metadata)
    );
    print('💾 Metadata saved: ${metadataFile.path}');
  }

  @override
  Map<String, dynamic> getMetrics() {
    return {
      'total_requests': _metrics.totalRequests,
      'successful_requests': _metrics.successfulRequests,
      'failed_requests': _metrics.failedRequests,
      'success_rate_percent': _metrics.getSuccessRate(),
      'total_input_tokens': _metrics.totalInputTokens,
      'total_output_tokens': _metrics.totalOutputTokens,
      'total_cache_read_tokens': _metrics.totalCacheReadTokens,
      'avg_latency_ms': _metrics.getAverageLatency(),
      'total_cost_usd': _metrics.totalCostUSD,
    };
  }

  @override
  void printMetrics() {
    print('\n' + '=' * 60);
    print('📊 ARTICLE GENERATION METRICS (Anthropic Claude)');
    print('=' * 60);
    print('API Calls: ${_metrics.totalRequests}');
    print('Success Rate: ${_metrics.getSuccessRate().toStringAsFixed(1)}%');
    print('Input Tokens: ${_metrics.totalInputTokens}');
    print('Output Tokens: ${_metrics.totalOutputTokens}');
    print('Cache Reads: ${_metrics.totalCacheReadTokens}');
    print('Avg Latency: ${_metrics.getAverageLatency().toStringAsFixed(0)}ms');
    print('Total Cost: \$${_metrics.totalCostUSD.toStringAsFixed(4)}');
    print('=' * 60);
  }

  @override
  void dispose() {
    _client.endSession();
  }
}
