import 'package:googleai_dart/googleai_dart.dart';
import 'ai_provider.dart';

class GeminiArticleTitleGenerator implements AIArticleTitleGenerator {
  late final GoogleAIClient _gemini;

  GeminiArticleTitleGenerator({required String apiKey}) {
    _gemini = GoogleAIClient(apiKey: apiKey);
  }

  /// Generate SEO-friendly article titles from keyword list using Gemini AI
  /// The AI will automatically filter out brand-specific keywords
  @override
  Future<List<String>> generateArticleTitles(List<String> keywords) async {
    print('🤖 Calling Gemini AI to generate SEO-friendly article titles...');
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
Berikan HANYA daftar judul (satu per baris), tanpa penomoran atau penjelasan tambahan, Langsung mulai dengan judul artikel pertama.
WAJIB menggunakan bahasa Indonesia.
Pastikan judul tidak menyebutkan merek/brand tertentu.
''';

      final response = await _gemini.generateContent(
        modelId: 'gemini-2.5-flash',
        request: GenerateContentRequest(
          contents: [
            Content(
              parts: [Part(text: prompt)],
            ),
          ],
          generationConfig: const GenerationConfig(
            maxOutputTokens: null,
            temperature: 0.6,
          ),
        ),
      );

      final content = response.candidates?.first.content?.parts?.first.text ?? '';
      
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
      
      print('✅ Gemini generated ${titles.length} SEO-friendly article titles\n');
      
      return titles;
    } catch (e) {
      print('❌ Error generating article titles with Gemini: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _gemini.endSession();
  }
}
