import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';

class ArticleTitleGenerator {
  late final AnthropicClient _anthropic;

  ArticleTitleGenerator({required String apiKey}) {
    _anthropic = AnthropicClient(apiKey: apiKey);
  }

  /// Generate SEO-friendly article titles from keyword list using AI
  /// The AI will automatically filter out brand-specific keywords
  Future<List<String>> generateArticleTitles(List<String> keywords) async {
    print('🤖 Calling AI to generate SEO-friendly article titles...');
    print('📊 Analyzing ${keywords.length} keywords...\n');
    
    try {
      // Take up to 30 keywords for context
      final keywordList = keywords.take(30).join('\n');
      
      final prompt = '''
Anda adalah seorang ahli strategi konten SEO dengan pengalaman 10+ tahun.

Berdasarkan kata kunci yang ditemukan dari riset:
$keywordList

Tugas: Buatkan 5-10 judul artikel yang SEO friendly untuk konten blog yang terindeks google.

KETENTUAN PENTING:
1. KECUALIKAN kata kunci yang mengandung nama brand atau merek tertentu (seperti Shopee, Tokopedia, Wardah, Emina, Viva, Pigeon, Kahf, Glad2glow, G2G, Animate, dll)
2. Utamakan kombinasi kata kunci berdasar urutan teratas yang tidak mengandung merek/brand
3. Fokus pada topik umum yang informatif dan evergreen
4. Judul harus menarik dan clickable
5. Panjang judul ideal 50-70 karakter
6. Gunakan format yang engaging

FORMAT OUTPUT:
Berikan HANYA daftar judul (satu per baris), tanpa penomoran atau penjelasan tambahan.
WAJIB menggunakan bahasa Indonesia.
Pastikan judul tidak menyebutkan merek/brand tertentu.
''';

      final response = await _anthropic.createMessage(
        request: CreateMessageRequest(
          model: Model.modelId('claude-3-5-haiku-latest'),
          maxTokens: 600,
          messages: [
            Message(
              role: MessageRole.user,
              content: MessageContent.text(prompt),
            ),
          ],
        ),
      );

      final content = response.content.text;
      
      // Parse the response to extract titles
      final titles = content
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .map((line) {
            // Remove numbering if present (e.g., "1. ", "1) ", etc.)
            return line
                .replaceAll(RegExp(r'^\d+[\.\)]\s*'), '')
                .replaceAll(RegExp(r'^[-•*]\s*'), '') // Remove bullets
                .trim();
          })
          .where((line) {
            // Filter out lines that are clearly not titles
            return line.isNotEmpty &&
                   !line.startsWith('#') &&
                   !line.toLowerCase().contains('output') &&
                   !line.toLowerCase().contains('contoh') &&
                   !line.toLowerCase().contains('berikut') &&
                   line.length > 20 &&
                   line.length < 200;
          })
          .toList();
      
      print('✅ Generated ${titles.length} SEO-friendly article titles\n');
      
      return titles;
    } catch (e) {
      print('❌ Error generating article titles: $e');
      return [];
    }
  }

  void dispose() {
    // Cleanup if needed
  }
}
