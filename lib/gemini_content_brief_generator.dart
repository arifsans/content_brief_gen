import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:googleai_dart/googleai_dart.dart';
import 'ai_provider.dart';

/// Config constants for Gemini optimization
class GeminiBriefConfig {
  // Token limits
  static const int unifiedMaxTokens = 1500;
  static const int fallbackMaxTokens = 150;
  
  // Retry settings
  static const int maxRetries = 3;
  static const Duration initialRetryDelay = Duration(seconds: 1);
  static const Duration maxTimeout = Duration(minutes: 5);
  
  // Rate limiting
  static const Duration minRequestDelay = Duration(milliseconds: 500);
  
  // Model selection
  static const String model = 'gemini-2.5-flash-lite'; // Fast and efficient
}

/// Metrics collector for Gemini API calls
class GeminiMetricsCollector {
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
    // Input: $0.075 per 1M tokens (up to 128k context)
    // Output: $0.30 per 1M tokens
    final inputCost = (inputTokens / 1000000) * 0.075;
    final outputCost = (outputTokens / 1000000) * 0.30;
    totalCostUSD += (inputCost + outputCost);
  }
  
  Map<String, dynamic> getSummary() {
    final avgLatency = latenciesMs.isEmpty ? 0 : latenciesMs.reduce((a, b) => a + b) / latenciesMs.length;
    final successRate = totalRequests > 0 ? (successfulRequests / totalRequests * 100) : 0;
    final totalTokens = totalInputTokens + totalOutputTokens;
    final avgTokensPerRequest = totalRequests > 0 ? (totalTokens / totalRequests) : 0;
    
    return {
      'total_requests': totalRequests,
      'successful': successfulRequests,
      'failed': failedRequests,
      'success_rate_percent': successRate.toStringAsFixed(1),
      'total_cost_usd': totalCostUSD.toStringAsFixed(4),
      'avg_latency_ms': avgLatency.toInt(),
      'total_input_tokens': totalInputTokens,
      'total_output_tokens': totalOutputTokens,
      'total_tokens': totalTokens,
      'avg_tokens_per_request': avgTokensPerRequest.toInt(),
      'cache_hit_rate_percent': '0.0', // Gemini doesn't have prompt caching in the same way
      'cache_read_tokens': 0,
      'estimated_savings_usd': '0.0000',
    };
  }
  
  void printSummary() {
    final summary = getSummary();
    print('\n📊 GEMINI PERFORMANCE STATISTICS:');
    print('   Total requests: ${summary['total_requests']}');
    print('   Success rate: ${summary['success_rate_percent']}%');
    print('   Total cost: \$${summary['total_cost_usd']}');
    print('   Avg latency: ${summary['avg_latency_ms']}ms');
    print('\n🔤 TOKEN USAGE:');
    print('   Input tokens: ${summary['total_input_tokens']}');
    print('   Output tokens: ${summary['total_output_tokens']}');
    print('   Total tokens: ${summary['total_tokens']}');
    print('   Avg tokens/request: ${summary['avg_tokens_per_request']}');
  }
}

/// Gemini-based content brief generator
class GeminiContentBriefGenerator implements AIContentBriefGenerator {
  late final GoogleAIClient _gemini;
  final GeminiMetricsCollector metrics = GeminiMetricsCollector();
  DateTime? _lastRequestTime;
  
  GeminiContentBriefGenerator({required String apiKey}) {
    _gemini = GoogleAIClient(apiKey: apiKey);
  }

  @override
  Future<ContentBrief> generateContentBrief(
    String keyword,
    List<String> relatedKeywords,
  ) async {
    print('🚀 Creating content brief with Gemini for: "$keyword"');
    
    final stopwatch = Stopwatch()..start();
    
    try {
      // Rate limiting
      await _enforceRateLimit();
      
      // Generate all components in 1 call
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
        inputTokens: 0, // Gemini doesn't expose token counts in response
        outputTokens: 0,
      );
      
      print('✅ Brief completed in ${stopwatch.elapsedMilliseconds}ms');
      
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
      
      // Fallback to individual generation if unified fails
      print('🔄 Trying fallback generation...');
      return await _generateWithFallback(keyword, relatedKeywords);
    }
  }

  /// Generate unified brief in 1 API call
  Future<GenerateContentResponse> _generateUnifiedBrief(
    String keyword,
    List<String> relatedKeywords,
  ) async {
    // System instruction for Gemini
    final systemInstruction = '''
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
    "(H2) Heading pertama",
    "(H3) Heading kedua",
    "(H2) Heading ketiga"
  ],
  "related_keywords": [
    "keyword relevan 1",
    "keyword relevan 2"
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
    "(H2) Heading pertama",
    "(H3) Sub-heading pertama",
    "(H2) Heading kedua"
  ]
}

PENTING: Response HANYA JSON, tanpa teks lain. Bahasa Indonesia.
''';
    }

    final response = await _gemini.generateContent(
      modelId: GeminiBriefConfig.model,
      request: GenerateContentRequest(
        contents: [
          Content(
            parts: [Part(text: systemInstruction + '\n\n' + userPrompt)],
          ),
        ],
        generationConfig: GenerationConfig(
          maxOutputTokens: GeminiBriefConfig.unifiedMaxTokens,
          temperature: 0.6,
          topP: 1,
        ),
      ),
    );

    return response;
  }

  /// Parse unified response from JSON
  ContentBrief _parseUnifiedResponse(
    GenerateContentResponse response,
    String keyword,
    List<String> relatedKeywords,
  ) {
    try {
      // Get text content from response
      final content = response.candidates?.first.content?.parts?.first.text ?? '';
      
      // Extract JSON from response (handle markdown code blocks)
      String jsonStr = content.trim();
      
      // Handle markdown code blocks
      if (content.contains('```json')) {
        final start = content.indexOf('```json') + 7;
        final end = content.indexOf('```', start);
        if (end != -1) {
          jsonStr = content.substring(start, end).trim();
        } else {
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
      
      // Use AI-generated related keywords if available
      List<String> finalRelatedKeywords;
      if (data.containsKey('related_keywords') && data['related_keywords'] is List) {
        finalRelatedKeywords = (data['related_keywords'] as List)
            .map((e) => e.toString())
            .toList();
        print('✨ Gemini generated ${finalRelatedKeywords.length} brand-free related keywords');
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
        provider: 'gemini',
      );
      
    } catch (e) {
      print('⚠️ Parsing error: $e');
      print('📄 Raw response length: ${response.candidates?.first.content?.parts?.first.text?.length ?? 0}');
      
      // Try emergency JSON extraction
      final content = response.candidates?.first.content?.parts?.first.text ?? '';
      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}');
      
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        try {
          final emergencyJson = content.substring(jsonStart, jsonEnd + 1);
          print('🔧 Attempting emergency JSON extraction...');
          final data = jsonDecode(emergencyJson) as Map<String, dynamic>;
          
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
            provider: 'gemini',
          );
        } catch (emergencyError) {
          print('❌ Emergency parsing also failed: $emergencyError');
        }
      }
      
      throw Exception('Failed to parse unified response: $e');
    }
  }

  /// Fallback generation if unified fails
  Future<ContentBrief> _generateWithFallback(
    String keyword,
    List<String> relatedKeywords,
  ) async {
    print('🔄 Using fallback individual generation...');
    
    try {
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
        provider: 'gemini',
      );
      
    } catch (e) {
      print('❌ Fallback also failed: $e');
      rethrow;
    }
  }

  /// Generate single component (for fallback)
  Future<String> _generateComponent(
    String type,
    String keyword,
    List<String> relatedKeywords,
    {String? context}
  ) async {
    final prompts = {
      'topic': 'Posisikan diri anda sebagai SEO content writer yang sudah berpengalaman menulis artikel dan membuat content planning lebih dari 10 tahun sesuai guide seo friendly terupdate. \n\n Buat topik blog SEO-friendly (max 80 char) untuk keyword "$keyword". HANYA topik, tanpa penjelasan.',
      'title': 'Posisikan diri anda sebagai SEO content writer yang sudah berpengalaman menulis artikel dan membuat content planning lebih dari 10 tahun sesuai guide seo friendly terupdate. \n\n Buat judul H1 (50-60 char) untuk keyword "$keyword". HANYA judul, tanpa penjelasan.',
      'meta': 'Posisikan diri anda sebagai SEO content writer yang sudah berpengalaman menulis artikel dan membuat content planning lebih dari 10 tahun sesuai guide seo friendly terupdate. \n\n Buat meta description (150-160 char) untuk keyword "$keyword". HANYA meta desc, tanpa penjelasan.',
      'structure': 'Posisikan diri anda sebagai SEO content writer yang sudah berpengalaman menulis artikel dan membuat content planning lebih dari 10 tahun sesuai guide seo friendly terupdate. \n\n Buat struktur artikel tentang "$keyword" dengan mengikuti langkah berikut: 1. Memiliki H2, H3 sesuai SEO best practice, 2.Berikan keterangan tiap jenis heading, 3.Sesuaikan struktur dengan judul dan topik (Jika memiliki [angka], buat list berdasarkan jumlah angka tsb), 4.Flow logis dan engaging,. HANYA list heading (satu per baris), tanpa penjelasan. dengan contoh format (H2) Pendahuluan / (H3) Subtopik pertama',
    };
    
    final response = await _gemini.generateContent(
      modelId: GeminiBriefConfig.model,
      request: GenerateContentRequest(
        contents: [
          Content(
            parts: [Part(text: prompts[type]!)],
          ),
        ],
        generationConfig: GenerationConfig(
          maxOutputTokens: GeminiBriefConfig.fallbackMaxTokens,
          temperature: 0.6,
          topP: 1,
        ),
      ),
    );
    
    return response.candidates?.first.content?.parts?.first.text?.trim() ?? '';
  }

  /// Retry mechanism with exponential backoff
  Future<T> _callWithRetry<T>(
    Future<T> Function() apiCall,
  ) async {
    int attempt = 0;
    Duration delay = GeminiBriefConfig.initialRetryDelay;
    
    while (true) {
      try {
        return await apiCall().timeout(
          GeminiBriefConfig.maxTimeout,
          onTimeout: () => throw TimeoutException('API call timeout'),
        );
      } catch (e) {
        attempt++;
        
        if (attempt >= GeminiBriefConfig.maxRetries) {
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
      if (timeSinceLastRequest < GeminiBriefConfig.minRequestDelay) {
        final waitTime = GeminiBriefConfig.minRequestDelay - timeSinceLastRequest;
        await Future.delayed(waitTime);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  @override
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
      await txtFile.writeAsString(brief.toFormattedText());
      
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

  @override
  Map<String, dynamic> getMetrics() => metrics.getSummary();
  
  @override
  void printMetrics() => metrics.printSummary();
  
  @override
  void dispose() {
    // Cleanup if needed
  }
}
