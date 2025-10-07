import 'dart:io';
import 'dart:convert';
import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';
import 'package:http/http.dart' as http;

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

class ContentBriefGenerator {
  late final AnthropicClient _anthropic;
  
  // Cache performance tracking
  int _totalCacheWrites = 0;
  int _totalCacheReads = 0;
  double _totalCostSavings = 0.0;

  ContentBriefGenerator({required String apiKey}) {
    _anthropic = AnthropicClient(apiKey: apiKey);
  }

  /// Get cache performance statistics
  Map<String, dynamic> getCacheStats() {
    final hitRate = _totalCacheReads + _totalCacheWrites > 0 
        ? (_totalCacheReads / (_totalCacheReads + _totalCacheWrites) * 100)
        : 0.0;
    
    return {
      'cache_writes': _totalCacheWrites,
      'cache_reads': _totalCacheReads,
      'cache_hit_rate_percent': hitRate.toStringAsFixed(1),
      'estimated_cost_savings_tokens': _totalCostSavings.toInt(),
    };
  }

  /// Reset cache statistics
  void resetCacheStats() {
    _totalCacheWrites = 0;
    _totalCacheReads = 0;
    _totalCostSavings = 0.0;
  }

  /// Track cache usage from API response
  void _trackCacheUsage(Usage? usage) {
    if (usage != null) {
      if (usage.cacheCreationInputTokens != null) {
        _totalCacheWrites += usage.cacheCreationInputTokens!;
        print('🔄 Cache write: ${usage.cacheCreationInputTokens} tokens');
      }
      
      if (usage.cacheReadInputTokens != null) {
        _totalCacheReads += usage.cacheReadInputTokens!;
        // Estimate cost savings: cache read is 0.1x vs normal 1x cost
        _totalCostSavings += usage.cacheReadInputTokens! * 0.9;
        print('✅ Cache hit: ${usage.cacheReadInputTokens} tokens (${(usage.cacheReadInputTokens! * 0.9).toInt()} tokens hemat biaya)');
      }
      
      // Show total tokens for debugging
      print('📝 Total input tokens: ${usage.inputTokens}, output tokens: ${usage.outputTokens}');
    }
  }

  Future<ContentBrief> generateContentBrief(
    String keyword, 
    List<String> relatedKeywords
  ) async {
    print('🚀 Membuat content brief untuk: "$keyword"');
    print('📊 Statistik cache sebelum generation: ${getCacheStats()}');
    
    final topic = await _generateTopic(keyword, relatedKeywords);
    final title = await _generateTitle(keyword, topic);
    final metaDescription = await _generateMetaDescription(keyword, title);
    final articleStructure = await _generateArticleStructure(keyword, topic);

    final brief = ContentBrief(
      keyword: keyword,
      topic: topic,
      title: title,
      metaDescription: metaDescription,
      articleStructure: articleStructure,
      relatedKeywords: relatedKeywords,
      generatedAt: DateTime.now(),
    );

    print('✅ Content brief selesai untuk: "$keyword"');
    print('📊 Statistik cache setelah generation: ${getCacheStats()}');
    
    return brief;
  }

  /// Generate multiple content briefs with intelligent prompt caching optimization
  /// Uses individual API calls with shared cached prompts for maximum cost efficiency
  /// This is NOT true batch processing - use generateContentBriefsWithMessageBatch for real batching
  Future<List<ContentBrief>> generateContentBriefsBatch(
    List<String> keywords,
    List<String> sharedRelatedKeywords,
  ) async {
    print('🚀 Starting optimized batch generation for ${keywords.length} keywords...');
    print('💡 Using intelligent prompt caching for cost efficiency');
    
    final results = <ContentBrief>[];
    
    print('📊 Cache stats before batch: ${getCacheStats()}');
    
    for (int i = 0; i < keywords.length; i++) {
      final keyword = keywords[i];
      print('📝 [${i + 1}/${keywords.length}] Processing: "$keyword"');
      
      try {
        // Generate content brief components directly (no double calls)
        print('🔄 Generating topic...');
        final topic = await _generateTopic(keyword, sharedRelatedKeywords);
        
        print('🔄 Generating title...');
        final title = await _generateTitle(keyword, topic);
        
        print('🔄 Generating meta description...');
        final metaDescription = await _generateMetaDescription(keyword, title);
        
        print('🔄 Generating article structure...');
        final articleStructure = await _generateArticleStructure(keyword, topic);

        final brief = ContentBrief(
          keyword: keyword,
          topic: topic,
          title: title,
          metaDescription: metaDescription,
          articleStructure: articleStructure,
          relatedKeywords: sharedRelatedKeywords,
          generatedAt: DateTime.now(),
        );
        
        results.add(brief);
        print('✅ [${i + 1}/${keywords.length}] Completed: "$keyword"');
        print('📊 Current cache stats: ${getCacheStats()}');
        
      } catch (e) {
        print('❌ [${i + 1}/${keywords.length}] Failed: "$keyword" - $e');
        results.add(ContentBrief(
          keyword: keyword,
          topic: 'Generation failed: ${e.toString()}',
          title: 'Generation failed',
          metaDescription: 'Generation failed',
          articleStructure: ['Generation failed'],
          relatedKeywords: sharedRelatedKeywords,
          generatedAt: DateTime.now(),
        ));
      }
    }
    
    final finalStats = getCacheStats();
    print('📊 Final cache stats: $finalStats');
    print('💰 Estimated cost savings: ${finalStats['estimated_cost_savings_tokens']} tokens');
    print('🎯 Cache hit rate: ${finalStats['cache_hit_rate_percent']}%');
    print('🎉 Batch generation completed: ${results.length} content briefs generated');
    
    return results;
  }

  /// Generate multiple content briefs using Anthropic Message Batches (TRUE BATCH PROCESSING)
  /// This uses the real Anthropic Batch API for maximum cost efficiency
  Future<List<ContentBrief>> generateContentBriefsWithMessageBatch(
    List<String> keywords,
    List<String> sharedRelatedKeywords,
  ) async {
    print('🚀 Using Anthropic Message Batch API for cost-efficient processing');
    print('💡 True batch processing with up to 50% cost savings vs individual calls');
    print('🔄 Creating batch request for ${keywords.length} keywords...');
    
    // Create batch requests for all keywords
    final batchRequests = <BatchMessageRequest>[];
    
    for (int i = 0; i < keywords.length; i++) {
      final keyword = keywords[i];
      
      // Create 4 requests per keyword (topic, title, meta, structure)
      batchRequests.addAll([
        _createTopicBatchRequest(_sanitizeCustomId('${keyword}_topic_$i'), keyword, sharedRelatedKeywords),
        _createTitleBatchRequest(_sanitizeCustomId('${keyword}_title_$i'), keyword),
        _createMetaBatchRequest(_sanitizeCustomId('${keyword}_meta_$i'), keyword),
        _createStructureBatchRequest(_sanitizeCustomId('${keyword}_structure_$i'), keyword),
      ]);
    }

    // Submit batch
    final batchRequest = CreateMessageBatchRequest(requests: batchRequests);
    final batch = await _anthropic.createMessageBatch(request: batchRequest);
    
    print('📦 Batch created with ID: ${batch.id}');
    print('⏳ Waiting for batch processing...');
    
    // Poll for completion
    var currentBatch = batch;
    while (currentBatch.processingStatus == MessageBatchProcessingStatus.inProgress) {
      await Future.delayed(const Duration(seconds: 10));
      currentBatch = await _anthropic.retrieveMessageBatch(id: batch.id);
      print('⏳ Batch status: ${currentBatch.processingStatus}');
    }
    
    if (currentBatch.processingStatus != MessageBatchProcessingStatus.ended) {
      throw Exception('Batch processing failed with status: ${currentBatch.processingStatus}');
    }
    
    print('✅ Batch processing completed!');
    
    // Process results
    return await _processBatchResults(currentBatch, keywords, sharedRelatedKeywords);
  }

  /// Sanitize custom_id to match Anthropic's pattern: ^[a-zA-Z0-9_-]{1,64}$
  String _sanitizeCustomId(String customId) {
    // Replace spaces and special characters with underscores
    String sanitized = customId
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_') // Replace multiple underscores with single
        .replaceAll(RegExp(r'^_|_$'), ''); // Remove leading/trailing underscores
    
    // Ensure it's not empty and within 64 character limit
    if (sanitized.isEmpty) {
      sanitized = 'request';
    }
    
    if (sanitized.length > 64) {
      sanitized = sanitized.substring(0, 64);
    }
    
    return sanitized;
  }

  BatchMessageRequest _createTopicBatchRequest(String customId, String keyword, List<String> relatedKeywords) {
    return BatchMessageRequest(
      customId: customId,
      params: CreateMessageRequest(
        model: Model.modelId('claude-3-5-haiku-latest'),
        maxTokens: 100,
        system: CreateMessageRequestSystem.blocks([
          const Block.text(
            text: '''
Anda adalah seorang ahli strategi konten SEO dengan pengalaman 10+ tahun dalam menciptakan topik blog yang menarik, mudah ditemukan di mesin pencari, dan mendorong traffic organik.

KEAHLIAN UTAMA:
- Optimasi mesin pencari dan strategi kata kunci
- Content marketing dan engagement audiens  
- Analisis user intent dan perencanaan konten
- Riset konten kompetitif
- Ideasi topik untuk maksimalisasi click-through rate

PANDUAN PEMBUATAN TOPIK SEO:

1. INTEGRASI KATA KUNCI:
   - Masukkan kata kunci utama secara natural
   - Gunakan variasi semantik yang sesuai
   - Hindari keyword stuffing atau frasa yang tidak natural

2. ANALISIS USER INTENT:
   - Intent informational: "Cara", "Apa itu", "Panduan"
   - Intent komersial: "Terbaik", "Review", "Perbandingan"
   - Intent transaksional: "Beli", "Harga", "Promo"

3. FAKTOR ENGAGEMENT:
   - Gunakan power words: Lengkap, Ultimate, Terbukti, Rahasia
   - Sertakan angka: "5 Cara", "Top 10", "7 Tips"
   - Alamatkan pain points atau keinginan
   - Ciptakan curiosity gaps

4. BEST PRACTICES SEO:
   - Jaga judul 50-80 karakter untuk tampilan SERP optimal
   - Letakkan kata kunci penting di depan
   - Pastikan judul menarik tapi tidak clickbait
   - Pertimbangkan elemen seasonal/trending

SYARAT FORMAT:
- Maksimal 80 karakter
- Tidak menggunakan tanda kutip
- Tidak ada teks penjelasan tambahan
- Fokus pada topik yang actionable dan spesifik
            ''',
            cacheControl: const CacheControlEphemeral(),
          ),
        ]),
        messages: [
          Message(
            role: MessageRole.user,
            content: MessageContent.text('''
Primary keyword: "$keyword"
Related keywords: ${relatedKeywords.take(5).join(', ')}

Generate a compelling blog topic that incorporates the primary keyword naturally.
            '''),
          ),
        ],
      ),
    );
  }

  BatchMessageRequest _createTitleBatchRequest(String customId, String keyword) {
    return BatchMessageRequest(
      customId: customId,
      params: CreateMessageRequest(
        model: Model.modelId('claude-3-5-haiku-latest'),
        maxTokens: 80,
        system: CreateMessageRequestSystem.blocks([
          const Block.text(
            text: '''
Anda adalah seorang ahli SEO copywriter yang mengkhususkan diri dalam menciptakan judul H1 berperforma tinggi yang memaksimalkan ranking mesin pencari dan click-through rates.

KEAHLIAN OPTIMASI JUDUL:
- 15+ tahun di SEO dan content marketing
- Track record terbukti menciptakan judul ranking #1
- Expert dalam psikologi user dan click triggers
- Spesialis menyeimbangkan SEO dengan readability

FRAMEWORK PEMBUATAN JUDUL H1:

1. FUNDAMENTAL SEO:
   - Masukkan kata kunci utama secara natural dalam judul
   - Jaga judul antara 50-60 karakter untuk tampilan SERP optimal
   - Letakkan kata kunci penting di depan
   - Gunakan variasi semantik kata kunci yang sesuai

2. PSYCHOLOGICAL TRIGGERS:
   - Power words: Ultimate, Lengkap, Penting, Terbukti, Rahasia, Eksklusif
   - Angka dan spesifik: "7 Cara", "Dalam 10 Menit", "Panduan 2025"
   - Emotional hooks: Hemat, Perbaiki, Temukan, Ubah, Kuasai
   - Indikator urgensi: Sekarang, Hari Ini, Cepat, Instan

3. ELEMEN MENARIK KLIK:
   - Janjikan value atau outcome spesifik
   - Alamatkan pain points atau keinginan
   - Ciptakan curiosity tanpa clickbait
   - Gunakan kurung untuk konteks: [2025], [Panduan Expert], [Step-by-Step]

4. BEST PRACTICES FORMAT:
   - Kapitalisasi huruf pertama setiap kata penting
   - Hindari tanda baca berlebihan
   - Tidak ada tanda kutip atau karakter khusus yang merusak HTML
   - Pastikan judul mudah dipahami sekilas

POLA JUDUL TERBUKTI:
- "Cara [Aksi] [Kata Kunci]: Panduan Lengkap"
- "Panduan Ultimate [Kata Kunci] untuk [Tahun]"
- "[Angka] Tips [Kata Kunci] yang Benar-Benar Berhasil"
- "Kenapa [Masalah] dan Cara Mengatasinya Cepat"

SYARAT FORMAT:
- Panjang 50-60 karakter
- Tidak ada tanda kutip dalam output
- Tone profesional tapi engaging
- WAJIB menggunakan bahasa Indonesia
            ''',
            cacheControl: const CacheControlEphemeral(),
          ),
        ]),
        messages: [
          Message(
            role: MessageRole.user,
            content: MessageContent.text('''
Kata kunci utama: "$keyword"

Buatkan judul H1 yang dioptimasi SEO dengan memasukkan kata kunci secara natural sambil tetap sangat menarik untuk diklik. Hasilkan dalam bahasa Indonesia.
            '''),
          ),
        ],
      ),
    );
  }

  BatchMessageRequest _createMetaBatchRequest(String customId, String keyword) {
    return BatchMessageRequest(
      customId: customId,
      params: CreateMessageRequest(
        model: Model.modelId('claude-3-5-haiku-latest'),
        maxTokens: 150,
        system: CreateMessageRequestSystem.blocks([
          const Block.text(
            text: '''
Anda adalah seorang ahli SEO copywriter yang mengkhususkan diri dalam meta description yang mendorong click-through rates tinggi dari search engine results pages (SERPs).

KEAHLIAN META DESCRIPTION:
- 12+ tahun mengoptimasi meta description untuk perusahaan Fortune 500
- Track record terbukti meningkatkan CTR sebesar 25-40%
- Expert dalam optimasi search snippet
- Spesialis menyeimbangkan kebutuhan SEO dengan copy yang persuasif

FRAMEWORK OPTIMASI META DESCRIPTION:

1. KEBUTUHAN TEKNIS:
   - Jaga antara 150-160 karakter untuk tampilan SERP optimal
   - Masukkan kata kunci utama secara natural dalam 120 karakter pertama
   - Hindari pemotongan karakter dengan ellipsis (...)
   - Tidak ada karakter khusus yang merusak HTML

2. ELEMEN PERSUASIF:
   - Value proposition yang jelas dalam kalimat pertama
   - Alamatkan pain points atau keinginan spesifik
   - Masukkan kata aksi yang menarik: Temukan, Pelajari, Kuasai, Ubah
   - Gunakan angka dan spesifisitas yang relevan

3. PENYELARASAN SEARCH INTENT:
   - Sesuaikan dengan intent pencari (informational, commercial, transactional)
   - Janjikan outcome atau solusi spesifik
   - Cerminkan manfaat utama konten
   - Ciptakan urgensi tanpa spam

4. CLICK TRIGGERS:
   - Bahasa fokus manfaat: "Hemat waktu", "Tingkatkan profit", "Hindari kesalahan"
   - Indikator social proof: "Tips expert", "Strategi terbukti", "Rahasia industri"
   - Eksklusivitas: "Panduan lengkap", "Resource ultimate", "Semua yang dibutuhkan"
   - Curiosity gaps: "Rahasia untuk...", "Yang tidak diberitahu expert"

POLA META DESCRIPTION TERBUKTI:
- "Temukan [manfaat] dengan panduan [kata kunci] lengkap kami. Pelajari [outcome spesifik] dalam [timeframe]. Tips expert disertakan."
- "Kuasai [kata kunci] dengan strategi terbukti dari expert industri. Dapatkan [hasil spesifik] dan hindari kesalahan umum."
- "[Angka] tips [kata kunci] esensial yang [manfaat]. Belajar dari expert dan [aksi] seperti pro. Panduan lengkap tersedia."

SYARAT FORMAT:
- Total 150-160 karakter
- Kata kunci utama dalam 120 karakter pertama
- Value proposition yang jelas
- Tidak ada tanda kutip dalam output
- WAJIB menggunakan bahasa Indonesia
            ''',
            cacheControl: const CacheControlEphemeral(),
          ),
        ]),
        messages: [
          Message(
            role: MessageRole.user,
            content: MessageContent.text('''
Kata kunci: "$keyword"

Buatkan meta description yang menarik dengan memasukkan kata kunci utama dan membuat user ingin mengklik dari hasil pencarian. Hasilkan dalam bahasa Indonesia.
            '''),
          ),
        ],
      ),
    );
  }

  BatchMessageRequest _createStructureBatchRequest(String customId, String keyword) {
    return BatchMessageRequest(
      customId: customId,
      params: CreateMessageRequest(
        model: Model.modelId('claude-3-5-haiku-latest'),
        maxTokens: 300,
        system: CreateMessageRequestSystem.blocks([
          const Block.text(
            text: '''
Anda adalah seorang ahli strategi konten dan spesialis SEO dengan pengalaman 15+ tahun menciptakan struktur artikel yang ranking #1 di Google dan engage pembaca.

KEAHLIAN STRUKTUR ARTIKEL:
- Arsitektur konten untuk dampak SEO maksimal
- Optimasi user experience melalui alur yang logis
- Semantic SEO dan topic clustering
- Strategi optimasi featured snippet

BEST PRACTICES STRUKTUR ARTIKEL:

1. KEBUTUHAN HEADING H2:
   - Buat 6-8 bagian utama (level heading H2)
   - Masukkan kata kunci utama di 2-3 heading secara natural
   - Gunakan variasi semantik dan kata kunci terkait
   - Pastikan alur yang logis dan progresif

2. STRATEGI OPTIMASI SEO:
   - Letakkan kata kunci penting di heading-heading awal
   - Gunakan heading berbasis pertanyaan untuk featured snippets
   - Masukkan bagian perbandingan dan "vs" jika relevan
   - Buat heading yang layak FAQ untuk voice search

3. PRINSIP USER EXPERIENCE:
   - Mulai dengan konsep dasar
   - Berkembang dari topik basic ke advanced
   - Masukkan bagian praktis dan actionable
   - Akhiri dengan implementasi atau langkah selanjutnya

4. INDIKATOR KEDALAMAN KONTEN:
   - Setiap heading harus mendukung 200-300 kata konten
   - Campur berbagai tipe konten: how-to, contoh, tips, tools
   - Masukkan bagian teoritis dan praktis
   - Rencanakan untuk integrasi multimedia

POLA HEADING TERBUKTI:
- "Apa itu [Kata Kunci]? [Definisi/Overview Lengkap]"
- "Cara [Aksi] [Kata Kunci]: Panduan Step-by-Step"
- "[Angka] Manfaat/Keuntungan dari [Kata Kunci]"
- "Kesalahan [Kata Kunci] yang Umum dan Harus Dihindari"
- "Tools/Resources/Strategi [Kata Kunci] Terbaik"
- "[Kata Kunci] vs [Alternatif]: Perbandingan Lengkap"
- "Tips [Kata Kunci] Advanced untuk Hasil yang Lebih Baik"

SYARAT FORMAT:
- Kembalikan setiap heading pada baris baru
- Tidak ada penomoran, bullets, atau format khusus
- Gunakan sentence case (bukan title case)
- Jaga heading antara 40-70 karakter
- Pastikan setiap heading spesifik dan actionable
- WAJIB menggunakan bahasa Indonesia
            ''',
            cacheControl: const CacheControlEphemeral(),
          ),
        ]),
        messages: [
          Message(
            role: MessageRole.user,
            content: MessageContent.text('''
Kata kunci: "$keyword"

Buatkan outline artikel komprehensif dengan 6-8 heading H2 yang secara natural memasukkan kata kunci dan menciptakan alur yang logis dan engaging untuk pembaca. Hasilkan dalam bahasa Indonesia.
            '''),
          ),
        ],
      ),
    );
  }

  Future<List<ContentBrief>> _processBatchResults(
    MessageBatch batch,
    List<String> keywords,
    List<String> sharedRelatedKeywords,
  ) async {
    final results = <ContentBrief>[];
    
    try {
      print('📊 Processing batch results for ${keywords.length} keywords...');
      print('📋 Batch ID: ${batch.id}');
      print('📈 Batch Status: ${batch.processingStatus}');
      
      // Check if batch has a results file URL
      if (batch.resultsUrl != null) {
        print('📁 Batch results available at: ${batch.resultsUrl}');
        
        // In a production implementation, you would:
        // 1. Download the results file from batch.resultsUrl
        // 2. Parse the JSONL file containing all responses
        // 3. Extract responses by custom_id
        
        // For now, we'll implement a simplified approach that acknowledges
        // the batch was processed but falls back to individual calls
        // This is better than calling individual APIs during batch creation
        
        print('📥 Implementing TRUE batch results file processing...');
        
        // Retrieve the batch with results URL
        final completedBatch = await _anthropic.retrieveMessageBatch(id: batch.id);
        print('📁 Batch results URL: ${completedBatch.resultsUrl}');
        
        if (completedBatch.resultsUrl != null) {
          // Download and parse the batch results file
          print('📥 Downloading batch results from: ${completedBatch.resultsUrl}');
          
          try {
            final headers = {
              'anthropic-version': '2023-06-01',
              'x-api-key': _anthropic.apiKey,
            };
            final response = await http.get(Uri.parse(completedBatch.resultsUrl!), headers: headers);
            
            if (response.statusCode == 200) {
              final resultsContent = utf8.decode(response.bodyBytes);
              print('✅ Downloaded batch results (${resultsContent.length} characters)');
              
              // Parse JSONL (each line is a JSON object)
              final lines = resultsContent.split('\n').where((line) => line.trim().isNotEmpty);
              final batchResults = <String, Map<String, dynamic>>{};
              
              for (final line in lines) {
                try {
                  final result = jsonDecode(line);
                  final customId = result['custom_id'] as String;
                  
                  // Check if the batch request succeeded
                  if (result['result'] != null && result['result']['type'] == 'succeeded') {
                    // Track usage from batch results
                    if (result['result']['message'] != null && result['result']['message']['usage'] != null) {
                      final usage = result['result']['message']['usage'];
                      print('🔍 Batch result usage for $customId: $usage');
                      
                      // Convert to Usage object for tracking (simplified)
                      if (usage['cache_creation_input_tokens'] != null) {
                        _totalCacheWrites += usage['cache_creation_input_tokens'] as int;
                      }
                      if (usage['cache_read_input_tokens'] != null) {
                        _totalCacheReads += usage['cache_read_input_tokens'] as int;
                        _totalCostSavings += (usage['cache_read_input_tokens'] as int) * 0.9;
                      }
                    }
                    
                    // Extract content from response
                    if (result['result']['message'] != null && 
                        result['result']['message']['content'] != null &&
                        result['result']['message']['content'].isNotEmpty) {
                      
                      final content = result['result']['message']['content'][0]['text'] as String;
                      
                      // Parse custom_id to get keyword and type
                      final parts = customId.split('_');
                      if (parts.length >= 3) {
                        // Extract keyword from custom_id (everything except last 2 parts)
                        final keywordParts = parts.take(parts.length - 2).toList();
                        final keyword = keywordParts.join(' ').replaceAll('_', ' ');
                        final type = parts[parts.length - 2]; // topic, title, meta, structure
                        
                        // Debug: show parsed keyword and type
                        print('🔍 Parsed from custom_id "$customId": keyword="$keyword", type="$type"');
                        
                        if (!batchResults.containsKey(keyword)) {
                          batchResults[keyword] = {};
                        }
                        batchResults[keyword]![type] = _extractCleanContent(content, type);
                      }
                    }
                  } else {
                    print('⚠️ Batch request failed for $customId: ${result['result']}');
                  }
                } catch (e) {
                  print('⚠️ Error parsing batch result line: $e');
                  continue;
                }
              }
              
              print('📦 Parsed ${batchResults.length} keyword results from batch');
              
              // Create ContentBrief objects from batch results
              for (final keyword in keywords) {
                final keywordData = batchResults[keyword];
                if (keywordData != null && keywordData.isNotEmpty) {
                  // Parse article structure from text to list
                  final structureText = keywordData['structure'] ?? 'Struktur artikel tidak tersedia';
                  final articleStructure = _parseArticleStructure(structureText);
                  
                  final brief = ContentBrief(
                    keyword: keyword,
                    topic: keywordData['topic'] ?? 'Topik tidak tersedia',
                    title: keywordData['title'] ?? 'Judul tidak tersedia',
                    metaDescription: keywordData['meta'] ?? 'Meta description tidak tersedia',
                    articleStructure: articleStructure,
                    relatedKeywords: sharedRelatedKeywords,
                    generatedAt: DateTime.now(),
                  );
                  
                  results.add(brief);
                  print('✅ Created brief from batch results for: "$keyword"');
                } else {
                  print('⚠️ No batch results found for keyword: "$keyword"');
                  // Add fallback brief
                  results.add(ContentBrief(
                    keyword: keyword,
                    topic: 'Batch result not found',
                    title: 'Batch result not found',
                    metaDescription: 'Batch result not found',
                    articleStructure: ['Batch result not found'],
                    relatedKeywords: sharedRelatedKeywords,
                    generatedAt: DateTime.now(),
                  ));
                }
              }
              
            } else {
              throw Exception('Failed to download batch results: HTTP ${response.statusCode}');
            }
          } catch (downloadError) {
            throw Exception('Error downloading batch results: $downloadError');
          }
        } else {
          throw Exception('No results URL found in completed batch');
        }
        print('💡 Try to use individual processing instead of batch processing...');

      } else {
        print('❌ No results URL found in batch response');
        throw Exception('Batch processing failed: No results URL');
      }
      
      print('🎉 TRUE batch processing completed: ${results.length} content briefs generated');
      print('📊 Final cache stats: ${getCacheStats()}');
      return results;
      
    } catch (e) {
      print('❌ Error processing batch results: $e');
      throw Exception('Batch processing failed: $e');
    }
  }

  /// Extract clean content from batch API responses based on content type
  String _extractCleanContent(String rawContent, String type) {
    switch (type) {
      case 'topic':
        // Topic responses are usually clean and direct
        return rawContent.trim();
        
      case 'title':
        // Title responses often have formatting - extract the actual title
        final lines = rawContent.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty);
        for (final line in lines) {
          // Look for lines with ** formatting or clear title indicators
          if (line.startsWith('**') && line.endsWith('**')) {
            return line.replaceAll('**', '').trim();
          }
          // Look for lines that don't start with # or other markdown
          if (!line.startsWith('#') && !line.toLowerCase().contains('character count') && 
              !line.toLowerCase().contains('recommendation') && line.length > 10) {
            return line.trim();
          }
        }
        return rawContent.split('\n').first.trim();
        
      case 'meta':
        // Meta descriptions often have explanatory text - extract the actual description
        final lines = rawContent.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty);
        for (final line in lines) {
          // Skip markdown headers and analysis text
          if (!line.startsWith('#') && !line.startsWith('**') && !line.startsWith('-') &&
              !line.toLowerCase().contains('character count') && !line.toLowerCase().contains('optimization') &&
              line.length >= 100 && line.length <= 160) {
            return line.trim();
          }
        }
        // If no perfect match, take the first substantial line
        for (final line in lines) {
          if (!line.startsWith('#') && !line.startsWith('**') && line.length > 50) {
            return line.trim();
          }
        }
        return rawContent.split('\n').first.trim();
        
      case 'structure':
        // Structure responses contain the headings - extract them
        return rawContent.trim();
        
      default:
        return rawContent.trim();
    }
  }

  /// Parse article structure text into clean list of headings
  List<String> _parseArticleStructure(String structureText) {
    final lines = structureText.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty);
    final headings = <String>[];
    
    for (final line in lines) {
      // Skip markdown headers, dividers, and explanation text
      if (line.startsWith('#') || line.startsWith('**') || line.startsWith('---') ||
          line.toLowerCase().contains('outline') || line.toLowerCase().contains('rationale') ||
          line.toLowerCase().contains('strategy') || line.length < 20) {
        continue;
      }
      
      // Clean up the heading
      final cleanLine = line
          .replaceAll(RegExp(r'^\d+\.\s*'), '') // Remove numbering
          .replaceAll(RegExp(r'^-\s*'), '')     // Remove dashes
          .trim();
      
      if (cleanLine.isNotEmpty && cleanLine.length > 10) {
        headings.add(cleanLine);
      }
    }
    
    // If no headings found, try to split by common patterns
    if (headings.isEmpty) {
      final allText = structureText.replaceAll(RegExp(r'#.*\n'), '').trim();
      final potentialHeadings = allText.split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && line.length > 15 && line.length < 150)
          .toList();
      
      headings.addAll(potentialHeadings.take(8)); // Limit to 8 headings
    }
    
    return headings.isEmpty ? ['Struktur artikel tidak tersedia'] : headings;
  }

  Future<String> _generateTopic(String keyword, List<String> relatedKeywords) async {
    try {
      final response = await _anthropic.createMessage(
        request: CreateMessageRequest(
          model: Model.modelId('claude-3-5-haiku-latest'), // Use same model as batch
          maxTokens: 100,
          system: CreateMessageRequestSystem.blocks([
            const Block.text(
              text: '''
Anda adalah seorang ahli strategi konten SEO dengan pengalaman 10+ tahun dalam menciptakan topik blog yang menarik, mudah ditemukan di mesin pencari, dan mendorong traffic organik.

KEAHLIAN UTAMA:
- Optimasi mesin pencari dan strategi kata kunci
- Content marketing dan engagement audiens  
- Analisis user intent dan perencanaan konten
- Riset konten kompetitif
- Ideasi topik untuk maksimalisasi click-through rate

PANDUAN PEMBUATAN TOPIK SEO:

1. INTEGRASI KATA KUNCI:
   - Masukkan kata kunci utama secara natural
   - Gunakan variasi semantik yang sesuai
   - Hindari keyword stuffing atau frasa yang tidak natural

2. ANALISIS USER INTENT:
   - Intent informational: "Cara", "Apa itu", "Panduan"
   - Intent komersial: "Terbaik", "Review", "Perbandingan"
   - Intent transaksional: "Beli", "Harga", "Promo"

3. FAKTOR ENGAGEMENT:
   - Gunakan power words: Lengkap, Ultimate, Terbukti, Rahasia
   - Sertakan angka: "5 Cara", "Top 10", "7 Tips"
   - Alamatkan pain points atau keinginan
   - Ciptakan curiosity gaps

4. BEST PRACTICES SEO:
   - Jaga judul 50-80 karakter untuk tampilan SERP optimal
   - Letakkan kata kunci penting di depan
   - Pastikan judul menarik tapi tidak clickbait
   - Pertimbangkan elemen seasonal/trending

CONTOH TOPIK SUKSES:
- "Panduan Lengkap [Kata Kunci]: Tips Expert 2025"
- "Cara [Aksi] Seperti Pro: 7 Strategi Terbukti"
- "[Angka] Tips [Kata Kunci] Penting untuk Pemula"
- "Kenapa [Masalah] Terjadi dan Cara Mengatasinya"
- "Perbandingan [Kata Kunci] Terbaik: Temukan yang Tepat"

SYARAT FORMAT:
- Maksimal 80 karakter
- Tidak menggunakan tanda kutip
- Tidak ada teks penjelasan tambahan
- Fokus pada topik yang actionable dan spesifik
- Pastikan topik bisa mendukung artikel 1500+ kata
              ''',
              cacheControl: const CacheControlEphemeral(),
            ),
          ]),
          messages: [
            Message(
              role: MessageRole.user,
              content: MessageContent.text('''
Kata kunci utama: "$keyword"
Kata kunci terkait: ${relatedKeywords.take(5).join(', ')}

Buatkan topik blog yang menarik dengan memasukkan kata kunci utama secara natural sambil mempertimbangkan kata kunci terkait untuk relevansi semantik.
              '''),
            ),
          ],
        ),
      );

      // Track cache usage with detailed logging
      print('🔍 API Response Usage: ${response.usage}');
      if (response.usage != null) {
        print('📊 Input tokens: ${response.usage!.inputTokens}');
        print('📊 Output tokens: ${response.usage!.outputTokens}');
        print('📊 Cache creation: ${response.usage!.cacheCreationInputTokens}');
        print('📊 Cache read: ${response.usage!.cacheReadInputTokens}');
      }
      _trackCacheUsage(response.usage);

      return response.content.text;
    } catch (e) {
      print('Error generating topic: $e');
      return 'Topik tidak berhasil dibuat';
    }
  }

  Future<String> _generateTitle(String keyword, String topic) async {
    try {
      final response = await _anthropic.createMessage(
        request: CreateMessageRequest(
          model: Model.modelId('claude-3-5-haiku-latest'), // Use same model as batch
          maxTokens: 80,
          system: CreateMessageRequestSystem.blocks([
            const Block.text(
              text: '''
Anda adalah seorang ahli SEO copywriter yang mengkhususkan diri dalam menciptakan judul H1 berperforma tinggi yang memaksimalkan ranking mesin pencari dan click-through rates.

KEAHLIAN OPTIMASI JUDUL:
- 15+ tahun di SEO dan content marketing
- Track record terbukti menciptakan judul ranking #1
- Expert dalam psikologi user dan click triggers
- Spesialis menyeimbangkan SEO dengan readability

FRAMEWORK PEMBUATAN JUDUL H1:

1. FUNDAMENTAL SEO:
   - Masukkan kata kunci utama secara natural dalam judul
   - Jaga judul antara 50-60 karakter untuk tampilan SERP optimal
   - Letakkan kata kunci penting di depan
   - Gunakan variasi semantik kata kunci yang sesuai

2. PSYCHOLOGICAL TRIGGERS:
   - Power words: Ultimate, Lengkap, Penting, Terbukti, Rahasia, Eksklusif
   - Angka dan spesifik: "7 Cara", "Dalam 10 Menit", "Panduan 2025"
   - Emotional hooks: Hemat, Perbaiki, Temukan, Ubah, Kuasai
   - Indikator urgensi: Sekarang, Hari Ini, Cepat, Instan

3. ELEMEN MENARIK KLIK:
   - Janjikan value atau outcome spesifik
   - Alamatkan pain points atau keinginan
   - Ciptakan curiosity tanpa clickbait
   - Gunakan kurung untuk konteks: [2025], [Panduan Expert], [Step-by-Step]

4. BEST PRACTICES FORMAT:
   - Kapitalisasi huruf pertama setiap kata penting
   - Hindari tanda baca berlebihan
   - Tidak ada quotes, titik dua, atau karakter khusus
   - Pastikan judul masuk akal sekilas lihat

POLA JUDUL TERBUKTI:
- "Cara [Aksi] [Kata Kunci]: Panduan Lengkap"
- "Panduan Ultimate [Kata Kunci] untuk [Tahun]"
- "[Angka] Tips [Kata Kunci] yang Benar-Benar Berhasil"
- "Kenapa [Masalah] dan Cara Mengatasinya Cepat"

SYARAT FORMAT:
- Panjang 50-60 karakter
- Tidak ada tanda kutip dalam output
- Tone profesional tapi engaging
              ''',
              cacheControl: const CacheControlEphemeral(),
            ),
          ]),
          messages: [
            Message(
              role: MessageRole.user,
              content: MessageContent.text('''
Kata kunci utama: "$keyword"
Topik: "$topic"

Buatkan judul H1 yang dioptimasi SEO dengan memasukkan kata kunci secara natural sambil tetap sangat menarik untuk diklik.
              '''),
            ),
          ],
        ),
      );

      // Track cache usage with detailed logging
      print('🔍 API Response Usage: ${response.usage}');
      _trackCacheUsage(response.usage);

      return response.content.text;
    } catch (e) {
      print('Error generating title: $e');
      return 'Judul tidak berhasil dibuat';
    }
  }

  Future<String> _generateMetaDescription(String keyword, String title) async {
    try {
      final response = await _anthropic.createMessage(
        request: CreateMessageRequest(
          model: Model.modelId('claude-3-5-haiku-latest'), // Use same model as batch
          maxTokens: 150,
          system: CreateMessageRequestSystem.blocks([
            const Block.text(
              text: '''
Anda adalah seorang ahli SEO copywriter yang mengkhususkan diri dalam meta description yang mendorong click-through rates tinggi dari halaman hasil mesin pencari (SERPs).

KEAHLIAN META DESCRIPTION:
- 12+ tahun mengoptimasi meta description untuk perusahaan Fortune 500
- Track record terbukti meningkatkan CTR sebesar 25-40%
- Expert dalam optimasi search snippet
- Spesialis menyeimbangkan persyaratan SEO dengan copy persuasif

FRAMEWORK OPTIMASI META DESCRIPTION:

1. PERSYARATAN TEKNIS:
   - Jaga antara 150-160 karakter untuk tampilan SERP optimal
   - Masukkan kata kunci utama secara natural dalam 120 karakter pertama
   - Hindari pemotongan batas karakter dengan ellipsis (...)
   - Tidak ada karakter khusus yang rusak di HTML

2. ELEMEN PERSUASIF:
   - Value proposition yang jelas di kalimat pertama
   - Alamatkan pain points atau keinginan spesifik
   - Sertakan action words yang menarik: Temukan, Pelajari, Kuasai, Ubah
   - Gunakan angka dan spesifik bila relevan

3. ALIGNMENT SEARCH INTENT:
   - Sesuaikan dengan intent pencari (informational, commercial, transactional)
   - Janjikan outcome atau solusi spesifik
   - Refleksikan benefit utama konten
   - Ciptakan urgensi tanpa spam

4. CLICK TRIGGERS:
   - Bahasa fokus benefit: "Hemat waktu", "Tingkatkan profit", "Hindari kesalahan"
   - Indikator social proof: "Tips expert", "Strategi terbukti", "Rahasia industri"
   - Eksklusivitas: "Panduan lengkap", "Resource ultimate", "Semua yang dibutuhkan"
   - Curiosity gaps: "Rahasia untuk...", "Yang tidak diceritakan expert"

POLA META DESCRIPTION TERBUKTI:
- "Temukan [benefit] dengan panduan [kata kunci] lengkap kami. Pelajari [outcome spesifik] dalam [timeframe]. Tips expert disertakan."
- "Kuasai [kata kunci] dengan strategi terbukti dari expert industri. Dapatkan [hasil spesifik] dan hindari kesalahan umum."
- "[Angka] tips [kata kunci] penting yang [benefit]. Belajar dari expert dan [aksi] seperti pro. Panduan lengkap di dalam."

SYARAT FORMAT:
- Total 150-160 karakter
- Kata kunci utama dalam 120 karakter pertama
- Value proposition yang jelas
- Tidak ada tanda kutip dalam output
              ''',
              cacheControl: const CacheControlEphemeral(),
            ),
          ]),
          messages: [
            Message(
              role: MessageRole.user,
              content: MessageContent.text('''
Kata kunci: "$keyword"
Judul: "$title"

Tuliskan meta description yang menarik dengan memasukkan kata kunci utama dan membuat user ingin klik dari hasil pencarian.
              '''),
            ),
          ],
        ),
      );

      // Track cache usage with detailed logging
      print('🔍 API Response Usage: ${response.usage}');
      _trackCacheUsage(response.usage);

      return response.content.text;
    } catch (e) {
      print('Error generating meta description: $e');
      return 'Meta description tidak berhasil dibuat';
    }
  }

  Future<List<String>> _generateArticleStructure(String keyword, String topic) async {
    try {
      final response = await _anthropic.createMessage(
        request: CreateMessageRequest(
          model: Model.modelId('claude-3-5-haiku-latest'), // Use same model as batch
          maxTokens: 300,
          system: CreateMessageRequestSystem.blocks([
            const Block.text(
              text: '''
Anda adalah seorang ahli content strategist dan SEO specialist dengan pengalaman 15+ tahun menciptakan struktur artikel yang ranking #1 di Google dan engaging untuk pembaca.

KEAHLIAN STRUKTUR ARTIKEL:
- Arsitektur konten untuk dampak SEO maksimal
- Optimasi user experience melalui flow logis
- Semantic SEO dan topic clustering
- Strategi optimasi featured snippet

BEST PRACTICES STRUKTUR ARTIKEL:

1. PERSYARATAN HEADING H2:
   - Buat 6-8 bagian utama (level heading H2)
   - Masukkan kata kunci utama di 2-3 heading secara natural
   - Gunakan variasi semantik dan kata kunci terkait
   - Pastikan flow dan progres yang logis

2. STRATEGI OPTIMASI SEO:
   - Front-load kata kunci penting di heading awal
   - Gunakan heading berbasis pertanyaan untuk featured snippets
   - Sertakan bagian perbandingan dan "vs" bila relevan
   - Ciptakan heading yang FAQ-worthy untuk voice search

3. PRINSIP USER EXPERIENCE:
   - Mulai dengan konsep fundamental
   - Progres dari topik basic ke advanced
   - Sertakan bagian praktis dan actionable
   - Akhiri dengan implementasi atau next steps

4. INDIKATOR KEDALAMAN KONTEN:
   - Setiap heading harus mendukung 200-300 kata konten
   - Mix berbagai tipe konten: how-to, contoh, tips, tools
   - Sertakan bagian teoretis dan praktis
   - Rencanakan untuk integrasi multimedia

POLA HEADING TERBUKTI:
- "Apa itu [Kata Kunci]? [Definisi/Overview Lengkap]"
- "Cara [Aksi] [Kata Kunci]: Panduan Step-by-Step"
- "[Angka] Manfaat/Keuntungan [Kata Kunci]"
- "Kesalahan [Kata Kunci] Umum yang Harus Dihindari"
- "Tools/Resource/Strategi [Kata Kunci] Terbaik"
- "[Kata Kunci] vs [Alternatif]: Perbandingan Lengkap"
- "Tips [Kata Kunci] Advanced untuk Hasil Lebih Baik"

CONTOH STRUKTUR:

UNTUK KONTEN HOW-TO:
- Memahami [Kata Kunci]: Dasar-Dasar
- Persyaratan dan Prerequisites [Kata Kunci] Penting
- Panduan Implementasi [Kata Kunci] Step-by-Step
- Tantangan [Kata Kunci] Umum dan Solusinya
- Teknik [Kata Kunci] Advanced untuk Hasil Lebih Baik
- Tools dan Resource [Kata Kunci] yang Dibutuhkan
- Mengukur Kesuksesan [Kata Kunci]: Metrik Kunci
- Next Steps: Mengembangkan [Kata Kunci] Lebih Lanjut

UNTUK KONTEN PERBANDINGAN/REVIEW:
- Overview [Kata Kunci]: Yang Perlu Diketahui
- Fitur [Kata Kunci] Teratas untuk Dipertimbangkan
- [Kata Kunci] vs Alternatif: Perbandingan Detail
- Pro dan Kontra Berbagai Pendekatan [Kata Kunci]
- Opsi [Kata Kunci] Terbaik untuk Kebutuhan Berbeda
- Analisis Harga dan Value [Kata Kunci]
- Rekomendasi Expert dan Final Thoughts

SYARAT FORMAT:
- Return setiap heading di baris baru
- Tidak ada numbering, bullets, atau format khusus
- Gunakan sentence case (bukan title case)
- Jaga heading antara 40-70 karakter
- Pastikan setiap heading spesifik dan actionable
              ''',
              cacheControl: const CacheControlEphemeral(),
            ),
          ]),
          messages: [
            Message(
              role: MessageRole.user,
              content: MessageContent.text('''
Kata kunci: "$keyword"
Topik: "$topic"

Buatkan outline artikel yang komprehensif dengan 6-8 heading H2 yang secara natural memasukkan kata kunci dan menciptakan flow yang logis dan engaging untuk pembaca.
              '''),
            ),
          ],
        ),
      );

      // Track cache usage with detailed logging
      print('🔍 API Response Usage: ${response.usage}');
      _trackCacheUsage(response.usage);

      final text = response.content.text;
      return text.split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error generating article structure: $e');
      return ['Struktur artikel tidak berhasil dibuat'];
    }
  }

  void dispose() {
    // Cleanup if needed
  }

  Future<void> saveContentBrief(ContentBrief brief, {String? timestampedFolder}) async {
    final baseDir = timestampedFolder != null ? 'results/$timestampedFolder' : 'results/content_briefs';
    final resultsDir = Directory(baseDir);
    await resultsDir.create(recursive: true);
    
    final filename = '${brief.keyword.replaceAll(' ', '_').toLowerCase()}_content_brief.txt';
    final file = File('${resultsDir.path}/$filename');
    
    final content = '''
SEO CONTENT BRIEF
Generated: ${brief.generatedAt.toLocal()}

PRIMARY KEYWORD: ${brief.keyword}

TOPIC: ${brief.topic}

TITLE: ${brief.title}

META DESCRIPTION: ${brief.metaDescription}

ARTICLE STRUCTURE:
${brief.articleStructure.map((heading) => '• $heading').join('\n')}

RELATED KEYWORDS:
${brief.relatedKeywords.take(10).map((kw) => '• $kw').join('\n')}
''';
    
    await file.writeAsString(content);
    print('💾 Content brief saved: ${file.path}');
  }

  Future<void> saveContentBriefAsJson(ContentBrief brief, {String? timestampedFolder}) async {
    final baseDir = timestampedFolder != null ? 'results/$timestampedFolder' : 'results/content_briefs';
    final resultsDir = Directory(baseDir);
    await resultsDir.create(recursive: true);
    
    final filename = '${brief.keyword.replaceAll(' ', '_').toLowerCase()}_content_brief.json';
    final file = File('${resultsDir.path}/$filename');
    
    final encoder = JsonEncoder.withIndent('  ');
    final jsonContent = encoder.convert(brief.toJson());
    
    await file.writeAsString(jsonContent);
    print('💾 JSON brief saved: ${file.path}');
  }

  /// Save multiple content briefs from batch processing
  Future<void> saveBatchContentBriefs(List<ContentBrief> briefs, {String? timestampedFolder}) async {
    final baseDir = timestampedFolder != null ? 'results/$timestampedFolder' : 'results/content_briefs/batch';
    final resultsDir = Directory(baseDir);
    await resultsDir.create(recursive: true);
    
    print('💾 Saving ${briefs.length} content briefs from batch processing...');
    
    for (final brief in briefs) {
      // Save individual text files
      await saveContentBrief(brief, timestampedFolder: timestampedFolder);
      
      // Save individual JSON files
      await saveContentBriefAsJson(brief, timestampedFolder: timestampedFolder);
    }
    
    // Create a batch summary file
    final timestamp = DateTime.now().toIso8601String().split('T')[0];
    final summaryFile = File('${resultsDir.path}/batch_summary_$timestamp.json');
    
    final batchSummary = {
      'generated_at': DateTime.now().toIso8601String(),
      'total_briefs': briefs.length,
      'keywords': briefs.map((b) => b.keyword).toList(),
      'briefs': briefs.map((b) => b.toJson()).toList(),
    };
    
    final encoder = JsonEncoder.withIndent('  ');
    await summaryFile.writeAsString(encoder.convert(batchSummary));
    
    print('✅ Batch summary saved: ${summaryFile.path}');
    print('📊 Successfully saved ${briefs.length} content briefs');
  }
}