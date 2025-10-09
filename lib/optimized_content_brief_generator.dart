import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';

/// Model data untuk content brief yang dioptimalkan
class ContentBrief {
  final String keyword;
  final String topic;
  final String title;
  final String metaDescription;
  final List<String> articleStructure;
  final List<String> relatedKeywords;
  final DateTime generatedAt;

  ContentBrief({
    required this.keyword,
    required this.topic,
    required this.title,
    required this.metaDescription,
    required this.articleStructure,
    required this.relatedKeywords,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
    'keyword': keyword,
    'topic': topic,
    'title': title,
    'meta_description': metaDescription,
    'article_structure': articleStructure,
    'related_keywords': relatedKeywords,
    'generated_at': generatedAt.toIso8601String(),
  };
}

/// Config constants untuk optimasi
class BriefConfig {
  // Token limits (dioptimasi untuk efisiensi)
  static const int unifiedMaxTokens = 1500; // Untuk generation unified (increased to prevent truncation)
  static const int fallbackMaxTokens = 150; // Untuk fallback individual
  
  // Retry settings
  static const int maxRetries = 3;
  static const Duration initialRetryDelay = Duration(seconds: 1);
  static const Duration maxTimeout = Duration(minutes: 5);
  
  // Rate limiting
  static const Duration minRequestDelay = Duration(milliseconds: 500);
  
  // Prompt optimization
  static const bool useOptimizedPrompts = false;
}

/// Metrics collector untuk monitoring
class MetricsCollector {
  int totalRequests = 0;
  int successfulRequests = 0;
  int failedRequests = 0;
  int cacheHits = 0;
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
    
    // Track token usage
    totalInputTokens += inputTokens;
    totalOutputTokens += outputTokens;
    if (cacheReadTokens != null) {
      totalCacheReadTokens += cacheReadTokens;
    }
    
    // Calculate cost (Claude Sonnet 4.5 pricing - March 2025)
    // Input: $3.00 per 1M tokens
    // Output: $15.00 per 1M tokens
    // Cache write: $3.75 per 1M tokens (25% more than input)
    // Cache read: $0.30 per 1M tokens (90% cheaper than input)
    final inputCost = (inputTokens / 1000000) * 3.00;
    final outputCost = (outputTokens / 1000000) * 15.00;
    final cacheSavings = cacheReadTokens != null ? (cacheReadTokens / 1000000) * 2.70 : 0; // 3.00 - 0.30 = 2.70 savings
    
    totalCostUSD += (inputCost + outputCost - cacheSavings);
    
    if (cacheReadTokens != null && cacheReadTokens > 0) {
      cacheHits++;
    }
  }
  
  Map<String, dynamic> getSummary() {
    final avgLatency = latenciesMs.isEmpty ? 0 : latenciesMs.reduce((a, b) => a + b) / latenciesMs.length;
    final successRate = totalRequests > 0 ? (successfulRequests / totalRequests * 100) : 0;
    final cacheHitRate = totalRequests > 0 ? (cacheHits / totalRequests * 100) : 0;
    final totalTokens = totalInputTokens + totalOutputTokens;
    final avgTokensPerRequest = totalRequests > 0 ? (totalTokens / totalRequests) : 0;
    
    return {
      'total_requests': totalRequests,
      'successful': successfulRequests,
      'failed': failedRequests,
      'success_rate_percent': successRate.toStringAsFixed(1),
      'cache_hit_rate_percent': cacheHitRate.toStringAsFixed(1),
      'total_cost_usd': totalCostUSD.toStringAsFixed(4),
      'avg_latency_ms': avgLatency.toInt(),
      'estimated_savings_usd': ((cacheHits * 0.0001)).toStringAsFixed(4),
      'total_input_tokens': totalInputTokens,
      'total_output_tokens': totalOutputTokens,
      'total_cache_read_tokens': totalCacheReadTokens,
      'total_tokens': totalTokens,
      'avg_tokens_per_request': avgTokensPerRequest.toInt(),
    };
  }
  
  void printSummary() {
    final summary = getSummary();
    print('\n📊 STATISTIK PERFORMANCE:');
    print('   Total requests: ${summary['total_requests']}');
    print('   Success rate: ${summary['success_rate_percent']}%');
    print('   Cache hit rate: ${summary['cache_hit_rate_percent']}%');
    print('   Total cost: \$${summary['total_cost_usd']}');
    print('   Avg latency: ${summary['avg_latency_ms']}ms');
    print('   Cache savings: \$${summary['estimated_savings_usd']}');
    print('\n🔤 TOKEN USAGE:');
    print('   Input tokens: ${summary['total_input_tokens']}');
    print('   Output tokens: ${summary['total_output_tokens']}');
    print('   Cache read tokens: ${summary['total_cache_read_tokens']}');
    print('   Total tokens: ${summary['total_tokens']}');
    print('   Avg tokens/request: ${summary['avg_tokens_per_request']}');
  }
}

/// Generator content brief yang dioptimalkan untuk production
class OptimizedContentBriefGenerator {
  late final AnthropicClient _anthropic;
  final MetricsCollector metrics = MetricsCollector();
  DateTime? _lastRequestTime;
  
  OptimizedContentBriefGenerator({required String apiKey}) {
    _anthropic = AnthropicClient(apiKey: apiKey);
  }

  /// Generate content brief dengan unified approach (1 API call)
  /// Lebih efisien 75% dibanding 4 API calls terpisah
  Future<ContentBrief> generateContentBrief(
    String keyword,
    List<String> relatedKeywords,
  ) async {
    print('🚀 Membuat content brief untuk: "$keyword"');
    
    final stopwatch = Stopwatch()..start();
    
    try {
      // Rate limiting
      await _enforceRateLimit();
      
      // Generate semua komponen dalam 1 call
      final response = await _callWithRetry(() => 
        _generateUnifiedBrief(keyword, relatedKeywords)
      );
      
      stopwatch.stop();
      
      // Parse response
      final brief = _parseUnifiedResponse(response, keyword, relatedKeywords);
      
      // Record metrics
      metrics.recordRequest(
        success: true,
        latencyMs: stopwatch.elapsedMilliseconds,
        inputTokens: response.usage?.inputTokens ?? 0,
        outputTokens: response.usage?.outputTokens ?? 0,
        cacheReadTokens: response.usage?.cacheReadInputTokens,
      );
      
      print('✅ Brief selesai dalam ${stopwatch.elapsedMilliseconds}ms');
      
      return brief;
      
    } catch (e) {
      stopwatch.stop();
      metrics.recordRequest(
        success: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        inputTokens: 0,
        outputTokens: 0,
      );
      
      print('❌ Error: $e');
      
      // Fallback ke individual generation jika unified gagal
      print('🔄 Mencoba fallback generation...');
      return await _generateWithFallback(keyword, relatedKeywords);
    }
  }

  /// Generate unified brief dalam 1 API call (OPTIMIZED)
  Future<Message> _generateUnifiedBrief(
    String keyword,
    List<String> relatedKeywords,
  ) async {
    // Prompt yang diringkas untuk efisiensi token
    final systemPrompt = BriefConfig.useOptimizedPrompts
        ? _getOptimizedSystemPrompt()
        : _getDetailedSystemPrompt();
    
    // Build user prompt based on whether we have related keywords
    final String userPrompt;
    if (relatedKeywords.isEmpty) {
      userPrompt = '''
Keyword utama: "$keyword"

Buatkan content brief SEO terupdate (E-E-A-T, helpful content, intent mapping, NLP, dsb.) lengkap dengan format JSON berikut:
{
  "topic": "topik blog (max 80 char)",
  "title": "judul H1 (50-60 char)",
  "meta_description": "meta desc (150-160 char)",
  "article_structure": [
    "(JENIS HEADING. EX: H2) Heading pertama",
    "(JENIS HEADING. EX: H3) Heading kedua",
    ... ((JENIS HEADING. EX: H3) Heading ke-n)
  ],
  "related_keywords": [
    "keyword relevan 1",
    "keyword relevan 2",
    ... (5 keywords)
  ]
}

PENTING: 
- Response HANYA JSON, tanpa teks lain
- Fokus pada keywords umum dan informatif
- Bahasa Indonesia
- Pastikan JSON lengkap dan valid
''';
    } else {
      userPrompt = '''
Keyword utama: "$keyword"
Related keywords: ${relatedKeywords.take(5).join(', ')}

Buatkan content brief SEO lengkap dengan format JSON berikut:
{
  "topic": "topik blog (max 80 char)",
  "title": "judul H1 (50-60 char)",
  "meta_description": "meta desc (150-160 char)",
  "article_structure": [
    "Heading H2 pertama",
    "Heading H2 kedua",
    ... (6-8 heading)
  ]
}

PENTING: Response HANYA JSON, tanpa teks lain. Bahasa Indonesia.
''';
    }

    return await _anthropic.createMessage(
      request: CreateMessageRequest(
        model: Model.modelId('claude-sonnet-4-5-20250929'),
        maxTokens: BriefConfig.unifiedMaxTokens,
        system: CreateMessageRequestSystem.blocks([
          Block.text(
            text: systemPrompt,
            cacheControl: const CacheControlEphemeral(),
          ),
        ]),
        messages: [
          Message(
            role: MessageRole.user,
            content: MessageContent.text(userPrompt),
          ),
        ],
      ),
    );
  }

  /// Optimized system prompt (300 tokens vs 900 tokens)
  String _getOptimizedSystemPrompt() {
    return '''
Kamu adalah SEO expert untuk Indonesian market. Buat content brief yang:

TOPIK:
- Natural, tidak keyword stuffing
- 50-80 karakter
- Sesuai user intent (informational/commercial)

JUDUL H1:
- 50-60 karakter optimal untuk SERP
- Kata kunci di depan
- Engaging: gunakan angka, "Cara", "Panduan", "Tips"

META DESCRIPTION:
- 150-160 karakter
- Kata kunci dalam 120 char pertama
- Action words: Temukan, Pelajari, Kuasai
- Value proposition jelas

STRUKTUR ARTIKEL (6-8 H2):
- Kata kunci utama di 2-3 heading
- Flow logis: basic → advanced
- Format: "Apa itu [X]", "Cara [X]", "[N] Tips [X]"
- 40-70 char per heading

OUTPUT: JSON valid, Bahasa Indonesia.
''';
  }

  /// Detailed system prompt (fallback, original length)
  String _getDetailedSystemPrompt() {
    return '''
Posisikan diri anda sebagai SEO content writer yang sudah berpengalaman menulis artikel dan membuat content planning lebih dari 10 tahun sesuai guide seo friendly terupdate.

TUGAS: Buat konten planning menggunakan bahasa indonesia yang natural dan edukatif dengan guide dibawah ini : 

1. TOPIK BLOG:
   - Masukkan keyword utama secara natural
   - Target user intent yang jelas
   - 50-80 karakter
   
2. JUDUL H1:
   - Optimasi SERP (50-60 karakter)
   - Keyword di posisi depan
   - Engaging dan clickable
   
3. META DESCRIPTION:
   - 150-160 karakter total
   - Keyword dalam 120 karakter pertama
   - Value proposition yang jelas
   
4. STRUKTUR ARTIKEL:
   - Memiliki H2, H3 sesuai SEO best practice
   - Berikan keterangan tiap jenis heading
   - Sesuaikan struktur dengan judul dan topik (Jika memiliki [angka], buat list berdasarkan jumlah angka tsb)
   - Flow logis dan engaging

FORMAT: JSON valid. BAHASA: Indonesia.
''';
  }

  /// Parse unified response dari JSON
  ContentBrief _parseUnifiedResponse(
    Message response,
    String keyword,
    List<String> relatedKeywords,
  ) {
    try {
      // Get text content from response
      final content = response.content.text;
      
      // Extract JSON dari response (handle markdown code blocks)
      String jsonStr = content.trim();
      
      // Handle markdown code blocks with proper error checking
      if (content.contains('```json')) {
        final start = content.indexOf('```json') + 7;
        final end = content.indexOf('```', start);
        if (end != -1) {
          jsonStr = content.substring(start, end).trim();
        } else {
          // Fallback: take everything after ```json and find JSON boundaries
          final afterMarker = content.substring(start).trim();
          final jsonStart = afterMarker.indexOf('{');
          if (jsonStart != -1) {
            jsonStr = afterMarker.substring(jsonStart);
          } else {
            jsonStr = afterMarker;
          }
        }
      } else if (content.contains('```')) {
        final start = content.indexOf('```') + 3;
        final end = content.indexOf('```', start);
        if (end != -1) {
          jsonStr = content.substring(start, end).trim();
        } else {
          // Fallback: take everything after first ``` and find JSON boundaries
          final afterMarker = content.substring(start).trim();
          final jsonStart = afterMarker.indexOf('{');
          if (jsonStart != -1) {
            jsonStr = afterMarker.substring(jsonStart);
          } else {
            jsonStr = afterMarker;
          }
        }
      }
      
      // Clean up JSON string - remove any trailing non-JSON content
      if (jsonStr.startsWith('{')) {
        // Find the end of the JSON object by counting braces
        int braceCount = 0;
        int jsonEnd = -1;
        for (int i = 0; i < jsonStr.length; i++) {
          if (jsonStr[i] == '{') {
            braceCount++;
          } else if (jsonStr[i] == '}') {
            braceCount--;
            if (braceCount == 0) {
              jsonEnd = i + 1;
              break;
            }
          }
        }
        if (jsonEnd != -1) {
          jsonStr = jsonStr.substring(0, jsonEnd);
        }
      }
      
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      // Use AI-generated related keywords if available, otherwise use provided ones
      List<String> finalRelatedKeywords;
      if (data.containsKey('related_keywords') && data['related_keywords'] is List) {
        finalRelatedKeywords = (data['related_keywords'] as List)
            .map((e) => e.toString())
            .toList();
        print('✨ AI generated ${finalRelatedKeywords.length} brand-free related keywords');
      } else {
        finalRelatedKeywords = relatedKeywords;
      }
      
      return ContentBrief(
        keyword: keyword,
        topic: data['topic'] as String? ?? 'Topic generation failed',
        title: data['title'] as String? ?? 'Title generation failed',
        metaDescription: data['meta_description'] as String? ?? 'Meta description generation failed',
        articleStructure: (data['article_structure'] as List?)
            ?.map((e) => e.toString())
            .toList() ?? ['Structure generation failed'],
        relatedKeywords: finalRelatedKeywords,
        generatedAt: DateTime.now(),
      );
      
    } catch (e) {
      print('⚠️ Parsing error: $e');
      print('📄 Raw response length: ${response.content.text.length}');
      print('📄 Raw response preview: ${response.content.text.length > 200 ? response.content.text.substring(0, 200) + "..." : response.content.text}');
      
      // Try to extract any JSON-like content as a last resort
      final content = response.content.text;
      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}');
      
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        try {
          final emergencyJson = content.substring(jsonStart, jsonEnd + 1);
          print('🔧 Attempting emergency JSON extraction...');
          final data = jsonDecode(emergencyJson) as Map<String, dynamic>;
          
          // Use emergency parsed data
          List<String> finalRelatedKeywords;
          if (data.containsKey('related_keywords') && data['related_keywords'] is List) {
            finalRelatedKeywords = (data['related_keywords'] as List)
                .map((e) => e.toString())
                .toList();
          } else {
            finalRelatedKeywords = relatedKeywords;
          }
          
          print('✅ Emergency parsing successful!');
          return ContentBrief(
            keyword: keyword,
            topic: data['topic'] as String? ?? 'Topic generation failed',
            title: data['title'] as String? ?? 'Title generation failed',
            metaDescription: data['meta_description'] as String? ?? 'Meta description generation failed',
            articleStructure: (data['article_structure'] as List?)
                ?.map((e) => e.toString())
                .toList() ?? ['Structure generation failed'],
            relatedKeywords: finalRelatedKeywords,
            generatedAt: DateTime.now(),
          );
        } catch (emergencyError) {
          print('❌ Emergency parsing also failed: $emergencyError');
          
          // Final attempt: try to repair truncated JSON
          try {
            print('🔧 Attempting to repair truncated JSON...');
            var repairedJson = content.substring(jsonStart);
            
            // Remove incomplete trailing elements
            // Look for common truncation patterns
            repairedJson = repairedJson
                .replaceAll(RegExp(r',\s*"related_keywords"\s*:\s*\[.*$', dotAll: true), '')
                .replaceAll(RegExp(r',\s*$'), '');
            
            // Ensure proper closing
            if (!repairedJson.endsWith('}')) {
              // Count open braces to determine how many to close
              int openBraces = '{'.allMatches(repairedJson).length;
              int closeBraces = '}'.allMatches(repairedJson).length;
              repairedJson += '}' * (openBraces - closeBraces);
            }
            
            final repairedData = jsonDecode(repairedJson) as Map<String, dynamic>;
            
            print('✅ JSON repair successful!');
            return ContentBrief(
              keyword: keyword,
              topic: repairedData['topic'] as String? ?? 'Topic generation failed',
              title: repairedData['title'] as String? ?? 'Title generation failed',
              metaDescription: repairedData['meta_description'] as String? ?? 'Meta description generation failed',
              articleStructure: (repairedData['article_structure'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ?? ['Structure generation failed'],
              relatedKeywords: relatedKeywords, // Use provided keywords since AI ones were truncated
              generatedAt: DateTime.now(),
            );
          } catch (repairError) {
            print('❌ JSON repair also failed: $repairError');
          }
        }
      }
      
      throw Exception('Failed to parse unified response: $e');
    }
  }

  /// Fallback generation jika unified gagal (individual calls)
  Future<ContentBrief> _generateWithFallback(
    String keyword,
    List<String> relatedKeywords,
  ) async {
    print('🔄 Using fallback individual generation...');
    
    try {
      // Generate components individually dengan prompt ringkas
      final topic = await _callWithRetry(() => 
        _generateComponent('topic', keyword, relatedKeywords)
      );
      
      final title = await _callWithRetry(() => 
        _generateComponent('title', keyword, relatedKeywords, context: topic)
      );
      
      final meta = await _callWithRetry(() => 
        _generateComponent('meta', keyword, relatedKeywords, context: title)
      );
      
      final structure = await _callWithRetry(() => 
        _generateComponent('structure', keyword, relatedKeywords, context: topic)
      );
      
      return ContentBrief(
        keyword: keyword,
        topic: topic,
        title: title,
        metaDescription: meta,
        articleStructure: structure.split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList(),
        relatedKeywords: relatedKeywords,
        generatedAt: DateTime.now(),
      );
      
    } catch (e) {
      print('❌ Fallback also failed: $e');
      rethrow;
    }
  }

  /// Generate single component (untuk fallback)
  Future<String> _generateComponent(
    String type,
    String keyword,
    List<String> relatedKeywords,
    {String? context}
  ) async {
    final prompts = {
      'topic': 'Buat topik blog SEO-friendly (max 80 char) untuk keyword "$keyword". HANYA topik, tanpa penjelasan.',
      'title': 'Buat judul H1 (50-60 char) untuk keyword "$keyword". HANYA judul, tanpa penjelasan.',
      'meta': 'Buat meta description (150-160 char) untuk keyword "$keyword". HANYA meta desc, tanpa penjelasan.',
      'structure': 'Buat 6-8 heading H2 untuk artikel tentang "$keyword". HANYA list heading (satu per baris), tanpa penjelasan.',
    };
    
    final response = await _anthropic.createMessage(
      request: CreateMessageRequest(
        model: Model.modelId('claude-sonnet-4-5-20250929'),
        maxTokens: BriefConfig.fallbackMaxTokens,
        messages: [
          Message(
            role: MessageRole.user,
            content: MessageContent.text(prompts[type]!),
          ),
        ],
      ),
    );
    
    return response.content.text.trim();
  }

  /// Retry mechanism dengan exponential backoff
  Future<T> _callWithRetry<T>(
    Future<T> Function() apiCall,
  ) async {
    int attempt = 0;
    Duration delay = BriefConfig.initialRetryDelay;
    
    while (true) {
      try {
        return await apiCall().timeout(
          BriefConfig.maxTimeout,
          onTimeout: () => throw TimeoutException('API call timeout'),
        );
      } catch (e) {
        attempt++;
        
        if (attempt >= BriefConfig.maxRetries) {
          print('❌ Max retries reached. Last error: $e');
          rethrow;
        }
        
        print('⚠️ Attempt $attempt failed: $e');
        print('🔄 Retrying in ${delay.inSeconds}s...');
        
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }
  }

  /// Enforce rate limiting
  Future<void> _enforceRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < BriefConfig.minRequestDelay) {
        final waitTime = BriefConfig.minRequestDelay - timeSinceLastRequest;
        await Future.delayed(waitTime);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  /// Save content brief dengan error handling
  Future<void> saveContentBrief(ContentBrief brief, {String? timestampedFolder}) async {
    try {
      final baseDir = timestampedFolder != null ? 'results/$timestampedFolder' : 'results/content_briefs';
      final resultsDir = Directory(baseDir);
      await resultsDir.create(recursive: true);
      
      final safeFilename = brief.keyword
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .toLowerCase();
      
      // Save TXT
      final txtFile = File('${resultsDir.path}/${safeFilename}_content_brief.txt');
      await txtFile.writeAsString(_formatBriefAsText(brief));
      
      // Save JSON
      final jsonFile = File('${resultsDir.path}/${safeFilename}_content_brief.json');
      final encoder = JsonEncoder.withIndent('  ');
      await jsonFile.writeAsString(encoder.convert(brief.toJson()));
      
      print('💾 Saved: ${txtFile.path}');
      print('💾 Saved: ${jsonFile.path}');
      
    } catch (e) {
      print('❌ Error saving brief: $e');
      rethrow;
    }
  }

  /// Format brief sebagai text untuk readability
  String _formatBriefAsText(ContentBrief brief) {
    return '''
═══════════════════════════════════════════════════════════════
                    SEO CONTENT BRIEF
═══════════════════════════════════════════════════════════════

Generated: ${brief.generatedAt.toLocal().toString().split('.')[0]}
Generator: Optimized Brief Generator v2.0

───────────────────────────────────────────────────────────────
PRIMARY KEYWORD
───────────────────────────────────────────────────────────────
${brief.keyword}

───────────────────────────────────────────────────────────────
TOPIK BLOG
───────────────────────────────────────────────────────────────
${brief.topic}

───────────────────────────────────────────────────────────────
JUDUL H1
───────────────────────────────────────────────────────────────
${brief.title}

Character count: ${brief.title.length}
Optimal: ${brief.title.length >= 50 && brief.title.length <= 60 ? '✅' : '⚠️ ${brief.title.length < 50 ? 'Terlalu pendek' : 'Terlalu panjang'}'}

───────────────────────────────────────────────────────────────
META DESCRIPTION
───────────────────────────────────────────────────────────────
${brief.metaDescription}

Character count: ${brief.metaDescription.length}
Optimal: ${brief.metaDescription.length >= 150 && brief.metaDescription.length <= 160 ? '✅' : '⚠️ ${brief.metaDescription.length < 150 ? 'Terlalu pendek' : 'Terlalu panjang'}'}

───────────────────────────────────────────────────────────────
STRUKTUR ARTIKEL (${brief.articleStructure.length} Heading H2)
───────────────────────────────────────────────────────────────
${brief.articleStructure.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}

───────────────────────────────────────────────────────────────
RELATED KEYWORDS (Top 10)
───────────────────────────────────────────────────────────────
${brief.relatedKeywords.take(10).toList().asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}

═══════════════════════════════════════════════════════════════
                        END OF BRIEF
═══════════════════════════════════════════════════════════════
''';
  }

  /// Get metrics summary
  Map<String, dynamic> getMetrics() => metrics.getSummary();
  
  /// Print metrics summary
  void printMetrics() => metrics.printSummary();
  
  /// Print combined metrics (keyword research + content brief)
  static void printCombinedMetrics({
    required Map<String, dynamic> keywordMetrics,
    required Map<String, dynamic> briefMetrics,
  }) {
    print('\n' + '=' * 60);
    print('📊 COMBINED WORKFLOW METRICS');
    print('=' * 60);
    
    // Keyword Research Section
    print('\n🔍 KEYWORD RESEARCH PHASE:');
    print('   API calls: ${keywordMetrics['total_api_calls']}');
    print('   Success rate: ${keywordMetrics['success_rate_percent']}%');
    print('   Keywords found: ${keywordMetrics['total_keywords_found']}');
    print('   Avg latency: ${keywordMetrics['avg_latency_ms']}ms');
    
    // Content Brief Section
    print('\n📝 CONTENT BRIEF GENERATION:');
    print('   Total requests: ${briefMetrics['total_requests']}');
    print('   Success rate: ${briefMetrics['success_rate_percent']}%');
    print('   Cache hit rate: ${briefMetrics['cache_hit_rate_percent']}%');
    print('   Avg latency: ${briefMetrics['avg_latency_ms']}ms');
    
    // Token Usage Section
    print('\n🔤 TOKEN USAGE:');
    print('   Input tokens: ${briefMetrics['total_input_tokens']}');
    print('   Output tokens: ${briefMetrics['total_output_tokens']}');
    print('   Cache read tokens: ${briefMetrics['total_cache_read_tokens']}');
    print('   Total tokens: ${briefMetrics['total_tokens']}');
    print('   Avg tokens/request: ${briefMetrics['avg_tokens_per_request']}');
    
    // Cost Section
    print('\n💰 COST ANALYSIS:');
    print('   Total cost: \$${briefMetrics['total_cost_usd']}');
    print('   Cache savings: \$${briefMetrics['estimated_savings_usd']}');
    
    // Overall Stats
    final totalApiCalls = (keywordMetrics['total_api_calls'] as int) + (briefMetrics['total_requests'] as int);
    final totalTime = (keywordMetrics['avg_latency_ms'] as int) * (keywordMetrics['total_api_calls'] as int) + 
                      (briefMetrics['avg_latency_ms'] as int) * (briefMetrics['total_requests'] as int);
    final avgTime = totalApiCalls > 0 ? (totalTime / totalApiCalls).round() : 0;
    
    print('\n📈 WORKFLOW SUMMARY:');
    print('   Total API calls: $totalApiCalls');
    print('   Overall avg latency: ${avgTime}ms');
    print('   Keywords found: ${keywordMetrics['total_keywords_found']}');
    print('   Content briefs generated: ${briefMetrics['successful']}');
    
    print('=' * 60);
  }
  
  void dispose() {
    // Cleanup if needed
  }
}
