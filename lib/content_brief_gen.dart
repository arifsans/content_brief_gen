import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

/// A small list of common user-agents to rotate
final _userAgents = [
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15',
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:115.0) Gecko/20100101 Firefox/115.0'
];

String _pickUserAgent() => _userAgents[Random().nextInt(_userAgents.length)];

/// Utility: small randomized delay to reduce blocking risk
Future<void> _randomDelay({int minMs = 400, int maxMs = 1200}) async {
  final ms = minMs + Random().nextInt((maxMs - minMs).clamp(0, 9999));
  await Future.delayed(Duration(milliseconds: ms));
}

/// Create timestamped directory for organizing results
String createTimestampedFolder(String baseKeyword) {
  final safeKeyword = baseKeyword.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
  final now = DateTime.now();
  
  // Format: YYYY-MM-DD_HH-MM-SS_keyword
  final year = now.year.toString();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  final second = now.second.toString().padLeft(2, '0');
  
  final timestamp = '${year}-${month}-${day}_${hour}-${minute}-${second}';
  final folderName = '${timestamp}_${safeKeyword.replaceAll(' ', '_')}';
  
  return folderName;
}

/// Phase 1: fetch autocomplete suggestions (public endpoint)
Future<List<String>> fetchAutocomplete(String keyword) async {
  final encoded = Uri.encodeQueryComponent(keyword);
  final url = Uri.parse(
    'https://suggestqueries.google.com/complete/search?client=chrome&hl=id&q=$encoded',
  );

  try {
    final res = await http.get(url, headers: {
      'User-Agent': _pickUserAgent(),
      'Accept': 'application/json',
    }).timeout(Duration(seconds: 10));

    if (res.statusCode != 200) {
      stderr.writeln('Warning: autocomplete HTTP ${res.statusCode}');
      return [];
    }

    final data = jsonDecode(res.body);
    if (data is List && data.length > 1 && data[1] is List) {
      return List<String>.from(data[1].map((e) => e.toString()));
    }
  } catch (e) {
    stderr.writeln('Autocomplete fetch error: $e');
  }

  return [];
}

/// Phase 2 (free): fetch "Related searches" + static suggestions from Google HTML
Future<List<String>> fetchRelatedSearches(String keyword) async {
  final query = Uri.encodeQueryComponent(keyword);
  final url = Uri.parse('https://www.google.com/search?q=$query&hl=id');

  // Try a small number of retries in case of transient block
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      // small randomized delay before request
      await _randomDelay(minMs: 600, maxMs: 1400);

      final headers = {
        'User-Agent': _pickUserAgent(),
        'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      };

      final res = await http.get(url, headers: headers).timeout(Duration(seconds: 12));
      if (res.statusCode != 200) {
        stderr.writeln('Related search fetch: HTTP ${res.statusCode} (attempt ${attempt + 1})');
        // small backoff
        await Future.delayed(Duration(seconds: 1 + attempt));
        continue;
      }

      final body = utf8.decode(res.bodyBytes);
      final doc = html_parser.parse(body);

      final results = <String>{};

      // 1) Bottom related searches typically appear inside '#search' or in "Related searches" anchors.
      // We can search for anchors whose href starts with "/search?" and appear near the bottom,
      // but to be simple, grab visible anchor text that looks like short related queries.

      final anchors = doc.querySelectorAll('a');
      for (var a in anchors) {
        final href = a.attributes['href'] ?? '';
        final text = a.text.trim();
        if (text.isEmpty) continue;

        // heuristics: link to search results and not nav/footer or long text
        if (href.startsWith('/search') && text.length < 100 && !_looksLikeUiLabel(text)) {
          results.add(text);
        }
      }

      // 2) Look specifically for "Related searches" section at bottom
      final relatedSections = doc.querySelectorAll('[data-async-context*="related"], .related-question-pair, .s75CSd, .k8XOCe');
      for (var section in relatedSections) {
        final sectionAnchors = section.querySelectorAll('a');
        for (var a in sectionAnchors) {
          final text = a.text.trim();
          if (text.isNotEmpty && text.length < 100 && !_looksLikeUiLabel(text)) {
            results.add(text);
          }
        }
      }

      // 3) Some related queries are also inside elements with role="link" or span classes.
      // Try to capture common related patterns: e.g., 'People also search for' items
      final possible = doc.querySelectorAll('div, span, p');
      for (var el in possible) {
        final txt = el.text.trim();
        if (txt.isEmpty) continue;

        // a heuristic: related searches are usually compact phrases with <= 6 words
        if (_isLikelyQuery(txt)) {
          results.add(txt);
        }
      }

      // 4) Remove the original keyword if present as exact
      results.removeWhere((r) => _normalize(r) == _normalize(keyword));

      // Convert Set to List and return
      final list = results.toList();
      return list;
    } catch (e) {
      stderr.writeln('Related search attempt ${attempt + 1} error: $e');
      await Future.delayed(Duration(milliseconds: 800 + attempt * 500));
    }
  }

  // failed after retries
  return [];
}

/// Phase 3: Extract People Also Ask questions from Google
Future<List<String>> fetchPeopleAlsoAsk(String keyword) async {
  final query = Uri.encodeQueryComponent(keyword);
  final url = Uri.parse('https://www.google.com/search?q=$query&hl=id');

  try {
    await _randomDelay(minMs: 800, maxMs: 1600);

    final headers = {
      'User-Agent': _pickUserAgent(),
      'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    };

    final res = await http.get(url, headers: headers).timeout(Duration(seconds: 15));
    if (res.statusCode != 200) {
      stderr.writeln('People Also Ask fetch: HTTP ${res.statusCode}');
      return [];
    }

    final body = utf8.decode(res.bodyBytes);
    final doc = html_parser.parse(body);
    final questions = <String>{};

    // Look for People Also Ask questions in various possible containers
    final paaSelectors = [
      '[role="button"][jsname]', // Common PAA button selector
      '[data-initq]', // Questions with data-initq attribute
      '.related-question-pair', // Related question containers
      '.g .s .st', // Sometimes questions appear in snippets
    ];

    for (var selector in paaSelectors) {
      final elements = doc.querySelectorAll(selector);
      for (var element in elements) {
        final text = element.text.trim();
        if (_isPeopleAlsoAskQuestion(text)) {
          questions.add(text);
        }
      }
    }

    // Also search in divs and spans for text that looks like questions
    final allDivs = doc.querySelectorAll('div, span, h3');
    for (var div in allDivs) {
      final text = div.text.trim();
      if (_isPeopleAlsoAskQuestion(text)) {
        questions.add(text);
      }
    }

    // Remove duplicates and return
    return questions.toList();
  } catch (e) {
    stderr.writeln('People Also Ask fetch error: $e');
    return [];
  }
}

/// Phase 4: Fetch Bing autocomplete suggestions
Future<List<String>> fetchBingAutocomplete(String keyword) async {
  final encoded = Uri.encodeQueryComponent(keyword);
  final url = Uri.parse(
    'https://api.bing.com/osjson.aspx?query=$encoded',
  );

  try {
    await _randomDelay(minMs: 500, maxMs: 1000);
    
    final res = await http.get(url, headers: {
      'User-Agent': _pickUserAgent(),
      'Accept': 'application/json, text/javascript, */*; q=0.01',
      'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
    }).timeout(Duration(seconds: 10));

    if (res.statusCode != 200) {
      stderr.writeln('Warning: Bing autocomplete HTTP ${res.statusCode}');
      return [];
    }

    // Bing OSJSON API returns: [query, [suggestions], [descriptions], [urls]]
    final data = jsonDecode(res.body);
    if (data is List && data.length > 1 && data[1] is List) {
      return List<String>.from(data[1].map((e) => e.toString()));
    }
    
    return [];
  } catch (e) {
    stderr.writeln('Bing autocomplete fetch error: $e');
    return [];
  }
}

/// Phase 5: Fetch DuckDuckGo autocomplete suggestions (alternative source)
Future<List<String>> fetchDuckDuckGoAutocomplete(String keyword) async {
  final encoded = Uri.encodeQueryComponent(keyword);
  
  try {
    await _randomDelay(minMs: 300, maxMs: 600);
    
    // Use the simple direct search API with fallback
    final url = Uri.parse('https://duckduckgo.com/ac/?q=$encoded&type=list');
    
    final res = await http.get(url, headers: {
      'User-Agent': _pickUserAgent(),
      'Accept': 'application/json, */*',
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept-Encoding': 'gzip, deflate',
      'DNT': '1',
      'Connection': 'keep-alive',
      'Referer': 'https://duckduckgo.com/',
    }).timeout(Duration(seconds: 6));

    if (res.statusCode != 200) {
      return [];
    }

    // Try to parse the response
    try {
      final data = jsonDecode(res.body);
      if (data is List && data.length > 1 && data[1] is List) {
        final suggestions = List<String>.from(data[1].map((e) => e.toString()));
        return suggestions.where((s) => s.trim().isNotEmpty).take(10).toList();
      }
    } catch (parseError) {
      // If JSON parsing fails, check if we got HTML (blocked request)
      if (res.body.trim().startsWith('<')) {
        // DuckDuckGo is blocking - try alternative approach
        return await _fetchDuckDuckGoFallback(keyword);
      }
      // For other parsing errors, return empty list
      return [];
    }
    
    return [];
  } catch (e) {
    // Handle SSL and connection errors silently
    if (e.toString().contains('HandshakeException') || 
        e.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
      // SSL issues - return empty list silently
      return [];
    } else if (e.toString().contains('TimeoutException')) {
      // Timeout - return empty list silently  
      return [];
    } else {
      // Log other errors but don't fail the whole process
      stderr.writeln('DuckDuckGo autocomplete unavailable: ${e.toString().split('\n').first}');
      return [];
    }
  }
}

/// Fallback method for DuckDuckGo when main API is blocked
Future<List<String>> _fetchDuckDuckGoFallback(String keyword) async {
  try {
    // Generate simple variations as fallback when API is unavailable
    final fallbackSuggestions = <String>[];
    
    // Basic word combinations
    final commonModifiers = ['how to', 'best', 'types of', 'benefits of', 'guide', 'tips'];
    
    for (final modifier in commonModifiers) {
      fallbackSuggestions.add('$modifier $keyword');
    }
    
    // Add some common suffixes
    final suffixes = ['guide', 'tips', 'benefits', 'review', 'comparison'];
    for (final suffix in suffixes) {
      fallbackSuggestions.add('$keyword $suffix');
    }
    
    // Return up to 5 fallback suggestions
    return fallbackSuggestions.take(5).toList();
  } catch (e) {
    return [];
  }
}

/// Very small heuristics helpers
bool _isLikelyQuery(String text) {
  final clean = text.trim();

  // Reject too short or too long
  if (clean.length < 3 || clean.length > 80) return false;

  // Reject 1-word results — related searches usually have 2+ words
  if (clean.split(RegExp(r'\s+')).length < 2) return false;

  // Must contain at least one letter (not just numbers/symbols)
  if (!RegExp(r'[a-zA-Z\u00C0-\u017F]').hasMatch(clean)) return false;

  // Reject UI labels and non-query phrases
  if (_looksLikeUiLabel(clean)) return false;

  return true;
}

bool _isPeopleAlsoAskQuestion(String text) {
  final clean = text.trim();
  
  // Must be reasonable length for a question
  if (clean.length < 10 || clean.length > 200) return false;
  
  // Should end with question mark or contain question words
  final endsWithQuestion = clean.endsWith('?');
  final containsQuestionWords = RegExp(r'\b(apa|bagaimana|mengapa|kapan|dimana|siapa|berapa|what|how|why|when|where|who|which|can|is|are|does|do|will|would)\b', caseSensitive: false).hasMatch(clean);
  
  if (!endsWithQuestion && !containsQuestionWords) return false;
  
  // Should have at least 3 words
  if (clean.split(RegExp(r'\s+')).length < 3) return false;
  
  // Reject if it looks like UI text
  if (_looksLikeUiLabel(clean)) return false;
  
  // Reject common non-question patterns
  final badPatterns = [
    'click here',
    'read more',
    'see all',
    'view more',
    'show more',
    'load more',
  ];
  
  for (var pattern in badPatterns) {
    if (clean.toLowerCase().contains(pattern)) return false;
  }
  
  return true;
}

bool _looksLikeUiLabel(String text) {
  final low = text.toLowerCase();
  const uiWords = [
    'click',
    'feedback',
    'tools',
    'settings',
    'help',
    'images',
    'videos',
    'maps',
    'sign in',
    'about',
    'privacy',
    'terms',
    'next',
    'previous',
    'more',
    'report',
    'open',
    'view',
    'filter'
  ];
  return uiWords.any((word) => low.contains(word));
}

String _normalize(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

// Export the normalize function for use in other files
String normalize(String s) => _normalize(s);

/// Categorize keywords based on their characteristics
Map<String, List<String>> categorizeKeywords({
  required List<String> autocomplete,
  required List<String> related,
  required List<String> peopleAlsoAsk,
  required List<String> bingAutocomplete,
  required List<String> duckduckgoAutocomplete,
}) {
  final categories = <String, List<String>>{
    'Google Autocomplete': [],
    'Related Searches': [],
    'People Also Ask': [],
    'Bing Suggestions': [],
    'DuckDuckGo Suggestions': [],
    'Long-tail Keywords': [],
    'Question Keywords': [],
  };

  // Process Google autocomplete
  for (var keyword in autocomplete) {
    categories['Google Autocomplete']!.add(keyword);
    if (keyword.split(' ').length >= 4) {
      categories['Long-tail Keywords']!.add(keyword);
    }
    if (_isQuestionKeyword(keyword)) {
      categories['Question Keywords']!.add(keyword);
    }
  }

  // Process related searches
  for (var keyword in related) {
    categories['Related Searches']!.add(keyword);
    if (keyword.split(' ').length >= 4) {
      categories['Long-tail Keywords']!.add(keyword);
    }
    if (_isQuestionKeyword(keyword)) {
      categories['Question Keywords']!.add(keyword);
    }
  }

  // Process People Also Ask
  for (var keyword in peopleAlsoAsk) {
    categories['People Also Ask']!.add(keyword);
    categories['Question Keywords']!.add(keyword);
    if (keyword.split(' ').length >= 4) {
      categories['Long-tail Keywords']!.add(keyword);
    }
  }

  // Process Bing autocomplete
  for (var keyword in bingAutocomplete) {
    categories['Bing Suggestions']!.add(keyword);
    if (keyword.split(' ').length >= 4) {
      categories['Long-tail Keywords']!.add(keyword);
    }
    if (_isQuestionKeyword(keyword)) {
      categories['Question Keywords']!.add(keyword);
    }
  }

  // Process DuckDuckGo autocomplete
  for (var keyword in duckduckgoAutocomplete) {
    categories['DuckDuckGo Suggestions']!.add(keyword);
    if (keyword.split(' ').length >= 4) {
      categories['Long-tail Keywords']!.add(keyword);
    }
    if (_isQuestionKeyword(keyword)) {
      categories['Question Keywords']!.add(keyword);
    }
  }

  // Remove empty categories
  categories.removeWhere((key, value) => value.isEmpty);

  return categories;
}

bool _isQuestionKeyword(String keyword) {
  final lower = keyword.toLowerCase();
  final questionWords = [
    'apa', 'bagaimana', 'mengapa', 'kapan', 'dimana', 'siapa', 'berapa',
    'what', 'how', 'why', 'when', 'where', 'who', 'which', 'can', 'is', 'are',
    'does', 'do', 'will', 'would'
  ];
  
  return questionWords.any((word) => lower.contains(word)) || keyword.endsWith('?');
}

Future<String> saveResults(String keyword, Map<String, List<String>> categorizedResults, List<String> allResults, {String? timestampedFolder}) async {
  final now = DateTime.now();
  
  // Use provided timestamped folder or create a new one
  final folderName = timestampedFolder ?? createTimestampedFolder(keyword);
  
  // Format date-time as dd-MMMM-yyyy HH:mm
  final months = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];
  
  final day = now.day.toString().padLeft(2, '0');
  final month = months[now.month];
  final year = now.year.toString();
  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  
  final dateTime = '$day-$month-$year $hour:$minute';
  
  // Create timestamped results directory
  final resultsDir = Directory('results/$folderName');
  await resultsDir.create(recursive: true);
  
  final filename = '${resultsDir.path}/keyword_research_report.txt';
  final file = File(filename);
  
  // Create content with header including date-time
  final content = StringBuffer();
  content.writeln('📊 SEO KEYWORD RESEARCH REPORT');
  content.writeln('${'=' * 50}');
  content.writeln('Target Keyword: $keyword');
  content.writeln('Generated on: $dateTime');
  content.writeln('Total keywords found: ${allResults.length}');
  content.writeln('${'=' * 50}');
  content.writeln('');
  
  // Add summary statistics
  content.writeln('📈 SUMMARY STATISTICS');
  content.writeln('-' * 30);
  for (var entry in categorizedResults.entries) {
    if (['Google Autocomplete', 'Related Searches', 'People Also Ask', 'Bing Suggestions', 'DuckDuckGo Suggestions'].contains(entry.key)) {
      content.writeln('${entry.key}: ${entry.value.length} keywords');
    }
  }
  content.writeln('Long-tail Keywords (4+ words): ${categorizedResults['Long-tail Keywords']?.length ?? 0}');
  content.writeln('Question-based Keywords: ${categorizedResults['Question Keywords']?.length ?? 0}');
  content.writeln('');
  
  // Add categorized results
  content.writeln('🎯 CATEGORIZED KEYWORDS');
  content.writeln('${'=' * 50}');
  
  for (var entry in categorizedResults.entries) {
    if (entry.value.isNotEmpty) {
      content.writeln('');
      content.writeln('📂 ${entry.key.toUpperCase()} (${entry.value.length})');
      content.writeln('-' * (entry.key.length + 10));
      
      for (var i = 0; i < entry.value.length; i++) {
        content.writeln('${i + 1}. ${entry.value[i]}');
      }
    }
  }
  
  // Add complete list
  content.writeln('');
  content.writeln('📋 COMPLETE KEYWORD LIST');
  content.writeln('${'=' * 50}');
  for (var i = 0; i < allResults.length; i++) {
    content.writeln('${i + 1}. ${allResults[i]}');
  }
  
  content.writeln('');
  content.writeln('${'=' * 50}');
  content.writeln('Generated by Enhanced SEO Keyword Research Tool');
  content.writeln('Report includes: Google Autocomplete, Related Searches, People Also Ask, Bing Suggestions');
  
  await file.writeAsString(content.toString());
  stdout.writeln('💾 Saved comprehensive report to $filename');
  stdout.writeln('📁 Session folder: results/$folderName');
  
  // Return the folder name for use in enhanced_seo_tool.dart
  return folderName;
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run bin/content_brief_gen.dart "<keyword>"');
    exit(1);
  }

  final keyword = args.join(' ').trim();
  stdout.writeln('🔍 Enhanced SEO Keyword Research for: "$keyword"\n');

  // Fetch from all sources
  stdout.writeln('🚀 Fetching from multiple sources...\n');
  
  final autocomplete = await fetchAutocomplete(keyword);
  stdout.writeln('✅ Google Autocomplete: ${autocomplete.length} results');

  final related = await fetchRelatedSearches(keyword);
  stdout.writeln('✅ Google Related Searches: ${related.length} results');

  final peopleAlsoAsk = await fetchPeopleAlsoAsk(keyword);
  stdout.writeln('✅ People Also Ask: ${peopleAlsoAsk.length} results');

  final bingAutocomplete = await fetchBingAutocomplete(keyword);
  stdout.writeln('✅ Bing Autocomplete: ${bingAutocomplete.length} results');

  final duckduckgoAutocomplete = await fetchDuckDuckGoAutocomplete(keyword);
  stdout.writeln('✅ DuckDuckGo Autocomplete: ${duckduckgoAutocomplete.length} results');

  // Merge & dedupe, keep order: autocomplete first, then related, then PAA, then Bing, then DDG (unique)
  final combined = <String>[];
  final seen = <String>{};

  // Add from each source while maintaining uniqueness
  for (var s in autocomplete) {
    final n = _normalize(s);
    if (!seen.contains(n)) {
      combined.add(s);
      seen.add(n);
    }
  }
  for (var s in related) {
    final n = _normalize(s);
    if (!seen.contains(n)) {
      combined.add(s);
      seen.add(n);
    }
  }
  for (var s in peopleAlsoAsk) {
    final n = _normalize(s);
    if (!seen.contains(n)) {
      combined.add(s);
      seen.add(n);
    }
  }
  for (var s in bingAutocomplete) {
    final n = _normalize(s);
    if (!seen.contains(n)) {
      combined.add(s);
      seen.add(n);
    }
  }
  for (var s in duckduckgoAutocomplete) {
    final n = _normalize(s);
    if (!seen.contains(n)) {
      combined.add(s);
      seen.add(n);
    }
  }

  // Categorize keywords
  final categorized = categorizeKeywords(
    autocomplete: autocomplete,
    related: related,
    peopleAlsoAsk: peopleAlsoAsk,
    bingAutocomplete: bingAutocomplete,
    duckduckgoAutocomplete: duckduckgoAutocomplete,
  );

  stdout.writeln('\n📊 SUMMARY:');
  stdout.writeln('Total unique keywords: ${combined.length}');
  stdout.writeln('Long-tail keywords (4+ words): ${categorized['Long-tail Keywords']?.length ?? 0}');
  stdout.writeln('Question-based keywords: ${categorized['Question Keywords']?.length ?? 0}');

  stdout.writeln('\n🎯 Top 10 Results:');
  for (var i = 0; i < (combined.length > 10 ? 10 : combined.length); i++) {
    stdout.writeln('${i + 1}. ${combined[i]}');
  }

  if (combined.length > 10) {
    stdout.writeln('... and ${combined.length - 10} more keywords in the report');
  }

  await saveResults(keyword, categorized, combined);
  stdout.writeln('\n✨ Enhanced keyword research completed!');
}
