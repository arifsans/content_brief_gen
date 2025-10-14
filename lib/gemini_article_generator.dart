import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:content_brief_gen/word_document_generator.dart';
import 'package:googleai_dart/googleai_dart.dart';
import 'ai_provider.dart';

/// Configuration for Gemini article generation
class GeminiArticleConfig {
  static const int? maxTokens = 6000; // Limited to control article length (~2000 words)
  static const int maxRetries = 3;
  static const Duration initialRetryDelay = Duration(seconds: 2);
  static const Duration maxTimeout = Duration(minutes: 10);
  static const Duration minRequestDelay = Duration(milliseconds: 500);
  static const String model = 'gemini-2.5-flash';
}

/// Metrics collector for Gemini article generation
class GeminiArticleMetricsCollector {
  int totalRequests = 0;
  int successfulRequests = 0;
  int failedRequests = 0;
  double totalCostUSD = 0.0;
  List<int> latenciesMs = [];
  int totalInputTokens = 0;
  int totalOutputTokens = 0;
  
  void recordRequest({
    required bool success,
    required int latencyMs,
    required int inputTokens,
    required int outputTokens,
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
    
    // Calculate cost (Gemini 2.0 Flash pricing)
    final inputCost = inputTokens * 0.00001875 / 1000; // $0.01875 per 1M tokens
    final outputCost = outputTokens * 0.0000375 / 1000; // $0.0375 per 1M tokens
    totalCostUSD += inputCost + outputCost;
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

/// Article Generator using Google Gemini API
class GeminiArticleGenerator implements AIArticleGenerator {
  final String apiKey;
  final GoogleAIClient _client;
  final GeminiArticleMetricsCollector _metrics = GeminiArticleMetricsCollector();
  DateTime? _lastRequestTime;

  GeminiArticleGenerator({required this.apiKey})
      : _client = GoogleAIClient(apiKey: apiKey);

  @override
  Future<String> generateArticle(ContentBrief brief) async {
    print('📝 Generating full SEO-optimized article for: "${brief.keyword}"');
    print('   Using AI: Google Gemini 2.5 Flash');
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
    return '''You are an expert SEO content writer specializing in creating high-quality, engaging articles that rank on page one of Google search results and recommended by Google Search Generative Experience.

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
    Duration delay = GeminiArticleConfig.initialRetryDelay;

    while (attempt < GeminiArticleConfig.maxRetries) {
      attempt++;
      
      try {
        print('   → API call attempt $attempt/${GeminiArticleConfig.maxRetries}...');
        
        final response = await _client
            .generateContent(
              modelId: GeminiArticleConfig.model,
              request: GenerateContentRequest(
                contents: [
                  Content(
                    parts: [Part(text: prompt)],
                  ),
                ],
                generationConfig: GenerationConfig(
                  maxOutputTokens: GeminiArticleConfig.maxTokens,
                  temperature: 0.7,
                ),
              ),
            )
            .timeout(GeminiArticleConfig.maxTimeout);

        // Extract usage stats (Gemini API doesn't expose detailed token counts in response)
        final inputTokens = 0; // Not available in current API version
        final outputTokens = 0; // Not available in current API version

        // Record metrics
        _metrics.recordRequest(
          success: true,
          latencyMs: DateTime.now().difference(DateTime.now()).inMilliseconds,
          inputTokens: inputTokens,
          outputTokens: outputTokens,
        );

        // Extract article text
        if (response.candidates == null || response.candidates!.isEmpty) {
          throw Exception('Empty response from API');
        }

        final candidate = response.candidates!.first;
        if (candidate.content?.parts == null || candidate.content!.parts!.isEmpty) {
          throw Exception('No content in response');
        }

        final text = candidate.content!.parts!
            .where((part) => part.text != null)
            .map((part) => part.text!)
            .join('\n');

        if (text.isEmpty) {
          throw Exception('Empty text in response');
        }

        return text;
        
      } catch (e) {
        print('   ⚠️ Attempt $attempt failed: $e');
        
        _metrics.recordRequest(
          success: false,
          latencyMs: 0,
          inputTokens: 0,
          outputTokens: 0,
        );

        if (attempt >= GeminiArticleConfig.maxRetries) {
          print('   ❌ All retry attempts exhausted');
          rethrow;
        }

        print('   ⏳ Retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }

    throw Exception('Failed after ${GeminiArticleConfig.maxRetries} attempts');
  }

  Future<void> _enforceRateLimit() async {
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < GeminiArticleConfig.minRequestDelay) {
        final waitTime = GeminiArticleConfig.minRequestDelay - elapsed;
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

    // Save as WordPress-ready HTML
    try {
      final htmlContent = _convertToWordPressHTML(article);
      final htmlFile = File('${resultsDir.path}/${safeFilename}_article_wordpress.html');
      await htmlFile.writeAsString(htmlContent);
      print('💾 WordPress HTML saved: ${htmlFile.path}');
      print('   ✨ Ready to copy-paste into WordPress editor!');
    } catch (e) {
      print('   ⚠️ Failed to generate WordPress HTML: $e');
    }

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
      'ai_provider': 'google_gemini',
      'model': GeminiArticleConfig.model,
      'word_count': article.split(' ').length,
      'character_count': article.length,
    };

    final metadataFile = File('${resultsDir.path}/${safeFilename}_article_metadata.json');
    await metadataFile.writeAsString(
      JsonEncoder.withIndent('  ').convert(metadata)
    );
    print('💾 Metadata saved: ${metadataFile.path}');
  }

  /// Convert Markdown article to WordPress-ready HTML
  String _convertToWordPressHTML(String markdown) {
    final buffer = StringBuffer();
    final lines = markdown.split('\n');
    
    bool inList = false;
    bool inOrderedList = false;
    
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim();
      
      if (line.isEmpty) {
        // Close any open lists
        if (inList) {
          buffer.writeln('</ul>');
          inList = false;
        }
        if (inOrderedList) {
          buffer.writeln('</ol>');
          inOrderedList = false;
        }
        buffer.writeln();
        continue;
      }
      
      // H1 heading
      if (line.startsWith('# ')) {
        if (inList) buffer.writeln('</ul>');
        if (inOrderedList) buffer.writeln('</ol>');
        inList = false;
        inOrderedList = false;
        
        final text = line.substring(2).trim();
        buffer.writeln('<h1>${_processInlineFormatting(text)}</h1>');
      }
      // H2 heading
      else if (line.startsWith('## ')) {
        if (inList) buffer.writeln('</ul>');
        if (inOrderedList) buffer.writeln('</ol>');
        inList = false;
        inOrderedList = false;
        
        final text = line.substring(3).trim();
        buffer.writeln('<h2>${_processInlineFormatting(text)}</h2>');
      }
      // H3 heading
      else if (line.startsWith('### ')) {
        if (inList) buffer.writeln('</ul>');
        if (inOrderedList) buffer.writeln('</ol>');
        inList = false;
        inOrderedList = false;
        
        final text = line.substring(4).trim();
        buffer.writeln('<h3>${_processInlineFormatting(text)}</h3>');
      }
      // Unordered list
      else if (line.startsWith('- ') || line.startsWith('* ')) {
        if (inOrderedList) {
          buffer.writeln('</ol>');
          inOrderedList = false;
        }
        if (!inList) {
          buffer.writeln('<ul>');
          inList = true;
        }
        final text = line.substring(2).trim();
        buffer.writeln('<li>${_processInlineFormatting(text)}</li>');
      }
      // Ordered list
      else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        if (inList) {
          buffer.writeln('</ul>');
          inList = false;
        }
        if (!inOrderedList) {
          buffer.writeln('<ol>');
          inOrderedList = true;
        }
        final text = line.replaceFirst(RegExp(r'^\d+\.\s'), '').trim();
        buffer.writeln('<li>${_processInlineFormatting(text)}</li>');
      }
      // Regular paragraph
      else {
        if (inList) {
          buffer.writeln('</ul>');
          inList = false;
        }
        if (inOrderedList) {
          buffer.writeln('</ol>');
          inOrderedList = false;
        }
        buffer.writeln('<p>${_processInlineFormatting(line)}</p>');
      }
    }
    
    // Close any remaining open lists
    if (inList) buffer.writeln('</ul>');
    if (inOrderedList) buffer.writeln('</ol>');
    
    return buffer.toString();
  }

  /// Process inline formatting (bold, italic) in text
  String _processInlineFormatting(String text) {
    // Process bold (**text**) - using <b> for WordPress Block Editor compatibility
    text = text.replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*'),
      (match) => '<b>${match.group(1)}</b>'
    );
    
    // Process italic (*text* but not **) - using <i> for WordPress Block Editor compatibility
    text = text.replaceAllMapped(
      RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)'),
      (match) => '<i>${match.group(1)}</i>'
    );
    
    return text;
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
      'avg_latency_ms': _metrics.getAverageLatency(),
      'total_cost_usd': _metrics.totalCostUSD,
    };
  }

  @override
  void printMetrics() {
    print('\n' + '=' * 60);
    print('📊 ARTICLE GENERATION METRICS (Google Gemini)');
    print('=' * 60);
    print('API Calls: ${_metrics.totalRequests}');
    print('Success Rate: ${_metrics.getSuccessRate().toStringAsFixed(1)}%');
    print('Input Tokens: ${_metrics.totalInputTokens}');
    print('Output Tokens: ${_metrics.totalOutputTokens}');
    print('Avg Latency: ${_metrics.getAverageLatency().toStringAsFixed(0)}ms');
    print('Total Cost: \$${_metrics.totalCostUSD.toStringAsFixed(4)}');
    print('=' * 60);
  }

  @override
  void dispose() {
    _client.endSession();
  }
}
