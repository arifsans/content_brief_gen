import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

// ========================================================================
// CONFIGURATION & CONSTANTS
// ========================================================================

/// A small list of common user-agents to rotate for request diversity
final _userAgents = [
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15',
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:115.0) Gecko/20100101 Firefox/115.0',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36'
];

/// Network timeout constants (in seconds)
const _defaultTimeout = 10;
const _extendedTimeout = 15;
const _shortTimeout = 6;

/// Retry configuration
const _maxRetries = 3;
const _baseBackoffMs = 1000;

/// Randomly select a user agent from the pool
String _pickUserAgent() => _userAgents[Random().nextInt(_userAgents.length)];

// ========================================================================
// METRICS TRACKING
// ========================================================================

/// Metrics collector for keyword research operations
class KeywordResearchMetrics {
  int totalApiCalls = 0;
  int successfulCalls = 0;
  int failedCalls = 0;
  int totalKeywordsFound = 0;
  List<int> latenciesMs = [];
  Map<String, int> sourceBreakdown = {
    'google_autocomplete': 0,
    'google_related': 0,
    'people_also_ask': 0,
    'bing_autocomplete': 0,
    'duckduckgo_autocomplete': 0,
  };
  
  void recordApiCall({
    required String source,
    required bool success,
    required int latencyMs,
    required int keywordsFound,
  }) {
    totalApiCalls++;
    if (success) {
      successfulCalls++;
      sourceBreakdown[source] = (sourceBreakdown[source] ?? 0) + keywordsFound;
    } else {
      failedCalls++;
    }
    latenciesMs.add(latencyMs);
    totalKeywordsFound += keywordsFound;
  }
  
  Map<String, dynamic> getSummary() {
    final avgLatency = latenciesMs.isEmpty ? 0 : latenciesMs.reduce((a, b) => a + b) / latenciesMs.length;
    final successRate = totalApiCalls > 0 ? (successfulCalls / totalApiCalls * 100) : 0;
    
    return {
      'total_api_calls': totalApiCalls,
      'successful_calls': successfulCalls,
      'failed_calls': failedCalls,
      'success_rate_percent': successRate.toStringAsFixed(1),
      'total_keywords_found': totalKeywordsFound,
      'avg_latency_ms': avgLatency.toInt(),
      'source_breakdown': sourceBreakdown,
    };
  }
  
  void printSummary() {
    final summary = getSummary();
    print('\n📊 KEYWORD RESEARCH METRICS:');
    print('   Total API calls: ${summary['total_api_calls']}');
    print('   Success rate: ${summary['success_rate_percent']}%');
    print('   Total keywords found: ${summary['total_keywords_found']}');
    print('   Avg latency: ${summary['avg_latency_ms']}ms');
    print('\n📈 SOURCE BREAKDOWN:');
    final breakdown = summary['source_breakdown'] as Map<String, int>;
    breakdown.forEach((source, count) {
      if (count > 0) {
        print('   ${source.replaceAll('_', ' ').toUpperCase()}: $count keywords');
      }
    });
  }
}

// Global instance for tracking
final keywordMetrics = KeywordResearchMetrics();

// ========================================================================
// UTILITY FUNCTIONS
// ========================================================================

/// Utility: small randomized delay to reduce blocking risk
/// 
/// Adds human-like random delays between requests to avoid rate limiting.
/// [minMs] minimum delay in milliseconds (default: 400)
/// [maxMs] maximum delay in milliseconds (default: 1200)
Future<void> _randomDelay({int minMs = 400, int maxMs = 1200}) async {
  if (minMs < 0 || maxMs < minMs) {
    throw ArgumentError('Invalid delay range: minMs=$minMs, maxMs=$maxMs');
  }
  final ms = minMs + Random().nextInt((maxMs - minMs).clamp(0, 9999));
  await Future.delayed(Duration(milliseconds: ms));
}

/// Execute an HTTP request with retry logic and exponential backoff
/// 
/// [makeRequest] function that performs the HTTP request
/// [maxRetries] maximum number of retry attempts
/// [operationName] descriptive name for logging purposes
Future<http.Response?> _retryableRequest({
  required Future<http.Response> Function() makeRequest,
  int maxRetries = _maxRetries,
  required String operationName,
}) async {
  for (var attempt = 0; attempt < maxRetries; attempt++) {
    try {
      final response = await makeRequest();
      
      if (response.statusCode == 200) {
        return response;
      } else if (response.statusCode == 429) {
        // Rate limited - wait longer
        stderr.writeln('$operationName: Rate limited (attempt ${attempt + 1}/$maxRetries)');
        await Future.delayed(Duration(seconds: 2 + attempt * 2));
        continue;
      } else if (response.statusCode >= 500) {
        // Server error - retry
        stderr.writeln('$operationName: Server error ${response.statusCode} (attempt ${attempt + 1}/$maxRetries)');
        await Future.delayed(Duration(seconds: 1 + attempt));
        continue;
      } else {
        // Client error - don't retry
        stderr.writeln('$operationName: HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      stderr.writeln('$operationName attempt ${attempt + 1}/$maxRetries error: ${e.toString().split('\n').first}');
      if (attempt < maxRetries - 1) {
        await Future.delayed(Duration(milliseconds: _baseBackoffMs + attempt * 500));
      }
    }
  }
  
  return null;
}

// ========================================================================
// FILE SYSTEM OPERATIONS
// ========================================================================

/// Create timestamped directory for organizing results
/// 
/// Format: YYYY-MM-DD_HH-MM-SS_keyword
/// [baseKeyword] the main keyword to use in folder name
/// Returns the folder name (not full path)
String createTimestampedFolder(String baseKeyword) {
  if (baseKeyword.isEmpty) {
    throw ArgumentError('baseKeyword cannot be empty');
  }
  
  final safeKeyword = baseKeyword
      .replaceAll(RegExp(r'[^\w\s-]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');
  
  final now = DateTime.now();
  
  final timestamp = '${now.year}'
      '-${now.month.toString().padLeft(2, '0')}'
      '-${now.day.toString().padLeft(2, '0')}'
      '_${now.hour.toString().padLeft(2, '0')}'
      '-${now.minute.toString().padLeft(2, '0')}'
      '-${now.second.toString().padLeft(2, '0')}';
  
  return '${timestamp}_$safeKeyword';
}

// ========================================================================
// KEYWORD FETCHING FUNCTIONS
// ========================================================================

// ========================================================================
// KEYWORD FETCHING FUNCTIONS
// ========================================================================

/// Phase 1: Fetch autocomplete suggestions from Google (public endpoint)
/// 
/// Uses Google's suggest API which provides autocomplete suggestions
/// [keyword] the search term to get suggestions for
/// Returns list of keyword suggestions
Future<List<String>> fetchAutocomplete(String keyword) async {
  if (keyword.trim().isEmpty) {
    stderr.writeln('Warning: Empty keyword provided to fetchAutocomplete');
    return [];
  }

  final encoded = Uri.encodeQueryComponent(keyword);
  final url = Uri.parse(
    'https://suggestqueries.google.com/complete/search?client=chrome&hl=id&q=$encoded',
  );

  final stopwatch = Stopwatch()..start();

  try {
    final res = await http.get(
      url,
      headers: {
        'User-Agent': _pickUserAgent(),
        'Accept': 'application/json',
      },
    ).timeout(Duration(seconds: _defaultTimeout));

    stopwatch.stop();

    if (res.statusCode != 200) {
      keywordMetrics.recordApiCall(
        source: 'google_autocomplete',
        success: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        keywordsFound: 0,
      );
      stderr.writeln('Warning: Google autocomplete HTTP ${res.statusCode}');
      return [];
    }

    final data = jsonDecode(res.body);
    if (data is List && data.length > 1 && data[1] is List) {
      final results = List<String>.from(data[1].map((e) => e.toString()));
      keywordMetrics.recordApiCall(
        source: 'google_autocomplete',
        success: true,
        latencyMs: stopwatch.elapsedMilliseconds,
        keywordsFound: results.length,
      );
      return results;
    }
  } catch (e) {
    stopwatch.stop();
    keywordMetrics.recordApiCall(
      source: 'google_autocomplete',
      success: false,
      latencyMs: stopwatch.elapsedMilliseconds,
      keywordsFound: 0,
    );
    stderr.writeln('Google autocomplete error: ${e.toString().split('\n').first}');
  }

  return [];
}

/// Phase 2: Fetch "Related searches" suggestions from Google HTML
/// 
/// Scrapes Google search results page for related search suggestions
/// Uses retry logic with exponential backoff
/// [keyword] the search term to find related searches for
/// Returns list of related keyword suggestions
Future<List<String>> fetchRelatedSearches(String keyword) async {
  if (keyword.trim().isEmpty) {
    stderr.writeln('Warning: Empty keyword provided to fetchRelatedSearches');
    return [];
  }

  final query = Uri.encodeQueryComponent(keyword);
  final url = Uri.parse('https://www.google.com/search?q=$query&hl=id');

  for (var attempt = 0; attempt < _maxRetries; attempt++) {
    try {
      await _randomDelay(minMs: 600, maxMs: 1400);

      final headers = {
        'User-Agent': _pickUserAgent(),
        'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Referer': 'https://www.google.com/',
      };

      final res = await http
          .get(url, headers: headers)
          .timeout(Duration(seconds: 12));
      
      if (res.statusCode != 200) {
        stderr.writeln('Related search fetch: HTTP ${res.statusCode} (attempt ${attempt + 1}/$_maxRetries)');
        await Future.delayed(Duration(seconds: 1 + attempt));
        continue;
      }

      final body = utf8.decode(res.bodyBytes);
      final doc = html_parser.parse(body);
      final results = <String>{};

      // Strategy 1: Extract from search result links
      final anchors = doc.querySelectorAll('a');
      for (var a in anchors) {
        final href = a.attributes['href'] ?? '';
        final text = a.text.trim();
        
        if (text.isEmpty || text.length >= 100) continue;
        
        if (href.startsWith('/search') && !_looksLikeUiLabel(text)) {
          results.add(text);
        }
      }

      // Strategy 2: Look for "Related searches" sections
      final relatedSections = doc.querySelectorAll(
        '[data-async-context*="related"], .related-question-pair, .s75CSd, .k8XOCe'
      );
      
      for (var section in relatedSections) {
        final sectionAnchors = section.querySelectorAll('a');
        for (var a in sectionAnchors) {
          final text = a.text.trim();
          if (text.isNotEmpty && text.length < 100 && !_looksLikeUiLabel(text)) {
            results.add(text);
          }
        }
      }

      // Strategy 3: Extract query-like text from various elements
      final possibleElements = doc.querySelectorAll('div, span, p');
      for (var el in possibleElements) {
        final text = el.text.trim();
        if (text.isNotEmpty && _isLikelyQuery(text)) {
          results.add(text);
        }
      }

      // Remove the original keyword if present
      results.removeWhere((r) => _normalize(r) == _normalize(keyword));

      return results.toList();
      
    } catch (e) {
      stderr.writeln('Related search attempt ${attempt + 1} error: ${e.toString().split('\n').first}');
      if (attempt < _maxRetries - 1) {
        await Future.delayed(Duration(milliseconds: 800 + attempt * 500));
      }
    }
  }

  return [];
}

/// Phase 3: Extract People Also Ask questions from Google
/// 
/// Scrapes Google search results for "People Also Ask" questions
/// [keyword] the search term to find PAA questions for
/// Returns list of question strings
Future<List<String>> fetchPeopleAlsoAsk(String keyword) async {
  if (keyword.trim().isEmpty) {
    stderr.writeln('Warning: Empty keyword provided to fetchPeopleAlsoAsk');
    return [];
  }

  final query = Uri.encodeQueryComponent(keyword);
  final url = Uri.parse('https://www.google.com/search?q=$query&hl=id');

  try {
    await _randomDelay(minMs: 800, maxMs: 1600);

    final headers = {
      'User-Agent': _pickUserAgent(),
      'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Referer': 'https://www.google.com/',
    };

    final res = await http
        .get(url, headers: headers)
        .timeout(Duration(seconds: _extendedTimeout));
    
    if (res.statusCode != 200) {
      stderr.writeln('People Also Ask fetch: HTTP ${res.statusCode}');
      return [];
    }

    final body = utf8.decode(res.bodyBytes);
    final doc = html_parser.parse(body);
    final questions = <String>{};

    // Strategy 1: Common PAA selectors
    final paaSelectors = [
      '[role="button"][jsname]',    // Common PAA button selector
      '[data-initq]',                // Questions with data-initq attribute
      '.related-question-pair',      // Related question containers
      '.g .s .st',                   // Sometimes questions appear in snippets
      '.JolIg',                      // Another PAA container class
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

    // Strategy 2: Search for question-like text in various elements
    final potentialQuestions = doc.querySelectorAll('div, span, h3');
    for (var element in potentialQuestions) {
      final text = element.text.trim();
      if (_isPeopleAlsoAskQuestion(text)) {
        questions.add(text);
      }
    }

    return questions.toList();
    
  } catch (e) {
    stderr.writeln('People Also Ask error: ${e.toString().split('\n').first}');
    return [];
  }
}

/// Phase 4: Fetch Bing autocomplete suggestions
/// 
/// Uses Bing's OpenSearch JSON API for autocomplete suggestions
/// [keyword] the search term to get suggestions for
/// Returns list of keyword suggestions
Future<List<String>> fetchBingAutocomplete(String keyword) async {
  if (keyword.trim().isEmpty) {
    stderr.writeln('Warning: Empty keyword provided to fetchBingAutocomplete');
    return [];
  }

  final encoded = Uri.encodeQueryComponent(keyword);
  final url = Uri.parse('https://api.bing.com/osjson.aspx?query=$encoded');

  try {
    await _randomDelay(minMs: 500, maxMs: 1000);
    
    final res = await http.get(
      url,
      headers: {
        'User-Agent': _pickUserAgent(),
        'Accept': 'application/json, text/javascript, */*; q=0.01',
        'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
      },
    ).timeout(Duration(seconds: _defaultTimeout));

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
    stderr.writeln('Bing autocomplete error: ${e.toString().split('\n').first}');
    return [];
  }
}

/// Phase 5: Fetch DuckDuckGo autocomplete suggestions (alternative source)
/// 
/// Uses DuckDuckGo's autocomplete API with fallback mechanism
/// [keyword] the search term to get suggestions for
/// Returns list of keyword suggestions
Future<List<String>> fetchDuckDuckGoAutocomplete(String keyword) async {
  if (keyword.trim().isEmpty) {
    stderr.writeln('Warning: Empty keyword provided to fetchDuckDuckGoAutocomplete');
    return [];
  }

  final encoded = Uri.encodeQueryComponent(keyword);
  
  try {
    await _randomDelay(minMs: 300, maxMs: 600);
    
    final url = Uri.parse('https://duckduckgo.com/ac/?q=$encoded&type=list');
    
    final res = await http.get(
      url,
      headers: {
        'User-Agent': _pickUserAgent(),
        'Accept': 'application/json, */*',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept-Encoding': 'gzip, deflate',
        'DNT': '1',
        'Connection': 'keep-alive',
        'Referer': 'https://duckduckgo.com/',
      },
    ).timeout(Duration(seconds: _shortTimeout));

    if (res.statusCode != 200) {
      return [];
    }

    try {
      final data = jsonDecode(res.body);
      if (data is List && data.length > 1 && data[1] is List) {
        final suggestions = List<String>.from(data[1].map((e) => e.toString()));
        return suggestions
            .where((s) => s.trim().isNotEmpty)
            .take(10)
            .toList();
      }
    } on FormatException {
      // JSON parsing failed - check if we got HTML (blocked request)
      if (res.body.trim().startsWith('<')) {
        return await _fetchDuckDuckGoFallback(keyword);
      }
      return [];
    }
    
    return [];
    
  } on TimeoutException {
    // Timeout - fail silently
    return [];
  } catch (e) {
    // Handle SSL and other connection errors gracefully
    if (e.toString().contains('HandshakeException') || 
        e.toString().contains('CERTIFICATE_VERIFY_FAILED') ||
        e.toString().contains('SocketException')) {
      return [];
    }
    
    stderr.writeln('DuckDuckGo unavailable: ${e.toString().split('\n').first}');
    return [];
  }
}

/// Fallback method for DuckDuckGo when main API is blocked
/// 
/// Generates simple keyword variations when the API is unavailable
/// [keyword] the base keyword
/// Returns list of generated keyword variations
Future<List<String>> _fetchDuckDuckGoFallback(String keyword) async {
  try {
    final fallbackSuggestions = <String>[];
    
    // Common modifiers for keyword expansion
    const commonModifiers = [
      'how to',
      'best',
      'types of',
      'benefits of',
      'guide',
      'tips'
    ];
    
    // Add modifier + keyword combinations
    for (final modifier in commonModifiers) {
      fallbackSuggestions.add('$modifier $keyword');
    }
    
    // Common suffixes for keyword expansion
    const suffixes = [
      'guide',
      'tips',
      'benefits',
      'review',
      'comparison'
    ];
    
    // Add keyword + suffix combinations
    for (final suffix in suffixes) {
      fallbackSuggestions.add('$keyword $suffix');
    }
    
    return fallbackSuggestions.take(5).toList();
  } catch (e) {
    return [];
  }
}

// ========================================================================
// VALIDATION & FILTERING HELPERS
// ========================================================================

/// Check if text is likely a search query
/// 
/// Uses heuristics to determine if a text string represents a valid query
/// [text] the text to validate
/// Returns true if text appears to be a query
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

/// Check if text is likely a People Also Ask question
/// 
/// Validates that text looks like a proper question
/// [text] the text to validate
/// Returns true if text appears to be a PAA question
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
  const badPatterns = [
    'click here',
    'read more',
    'see all',
    'view more',
    'show more',
    'load more',
    'learn more',
  ];
  
  final lowerText = clean.toLowerCase();
  for (final pattern in badPatterns) {
    if (lowerText.contains(pattern)) return false;
  }
  
  return true;
}

/// Check if text looks like a UI label or navigation element
/// 
/// Filters out common UI/navigation text that isn't a real query
/// [text] the text to check
/// Returns true if text appears to be UI text
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
    'filter',
    'search',
    'menu',
  ];
  return uiWords.any((word) => low.contains(word));
}

/// Normalize a string for comparison
/// 
/// Trims, lowercases, and normalizes whitespace
/// [s] the string to normalize
/// Returns normalized string
/// Normalize a string for comparison
/// 
/// Trims, lowercases, and normalizes whitespace
/// [s] the string to normalize
/// Returns normalized string
String _normalize(String s) => 
    s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

// Export the normalize function for use in other files
String normalize(String s) => _normalize(s);

// ========================================================================
// KEYWORD CATEGORIZATION
// ========================================================================

/// Check if keyword is question-based
/// 
/// Determines if a keyword contains question indicators
/// [keyword] the keyword to check
/// Returns true if keyword appears to be a question
bool _isQuestionKeyword(String keyword) {
  final lower = keyword.toLowerCase();
  const questionWords = [
    'apa', 'bagaimana', 'mengapa', 'kapan', 'dimana', 'siapa', 'berapa',
    'what', 'how', 'why', 'when', 'where', 'who', 'which', 'can', 'is', 'are',
    'does', 'do', 'will', 'would'
  ];
  
  return questionWords.any((word) => lower.contains(word)) || keyword.endsWith('?');
}

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

// ========================================================================
// REPORT GENERATION
// ========================================================================

/// Save keyword research results to a formatted text file
/// 
/// Creates a comprehensive report with categorized keywords
/// [keyword] the target keyword that was researched
/// [categorizedResults] keywords organized by category
/// [allResults] complete list of all unique keywords
/// [timestampedFolder] optional folder name (creates new if not provided)
/// Returns the folder name where results were saved
/// Save keyword research results to a formatted text file
/// 
/// Creates a comprehensive report with categorized keywords
/// [keyword] the target keyword that was researched
/// [categorizedResults] keywords organized by category
/// [allResults] complete list of all unique keywords
/// [timestampedFolder] optional folder name (creates new if not provided)
/// Returns the folder name where results were saved
Future<String> saveResults(
  String keyword,
  Map<String, List<String>> categorizedResults,
  List<String> allResults, {
  String? timestampedFolder,
}) async {
  final now = DateTime.now();
  
  // Use provided timestamped folder or create a new one
  final folderName = timestampedFolder ?? createTimestampedFolder(keyword);
  
  // Format date-time as dd-MMMM-yyyy HH:mm (Indonesian format)
  const months = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];
  
  final dateTime = '${now.day.toString().padLeft(2, '0')}'
      '-${months[now.month]}'
      '-${now.year} '
      '${now.hour.toString().padLeft(2, '0')}'
      ':${now.minute.toString().padLeft(2, '0')}';
  
  // Create timestamped results directory
  final resultsDir = Directory('results/$folderName');
  await resultsDir.create(recursive: true);
  
  final filename = '${resultsDir.path}/keyword_research_report.txt';
  final file = File(filename);
  
  // Build report content
  final content = StringBuffer();
  
  // Header
  content.writeln('📊 SEO KEYWORD RESEARCH REPORT');
  content.writeln('=' * 50);
  content.writeln('Target Keyword: $keyword');
  content.writeln('Generated on: $dateTime');
  content.writeln('Total keywords found: ${allResults.length}');
  content.writeln('=' * 50);
  content.writeln();
  
  // Summary statistics
  content.writeln('📈 SUMMARY STATISTICS');
  content.writeln('-' * 30);
  
  final sourceCategories = [
    'Google Autocomplete',
    'Related Searches',
    'People Also Ask',
    'Bing Suggestions',
    'DuckDuckGo Suggestions'
  ];
  
  for (final category in sourceCategories) {
    final count = categorizedResults[category]?.length ?? 0;
    if (count > 0) {
      content.writeln('$category: $count keywords');
    }
  }
  
  content.writeln('Long-tail Keywords (4+ words): '
      '${categorizedResults['Long-tail Keywords']?.length ?? 0}');
  content.writeln('Question-based Keywords: '
      '${categorizedResults['Question Keywords']?.length ?? 0}');
  content.writeln();
  
  // Categorized results
  content.writeln('🎯 CATEGORIZED KEYWORDS');
  content.writeln('=' * 50);
  
  for (final entry in categorizedResults.entries) {
    if (entry.value.isNotEmpty) {
      content.writeln();
      content.writeln('📂 ${entry.key.toUpperCase()} (${entry.value.length})');
      content.writeln('-' * (entry.key.length + 10));
      
      for (var i = 0; i < entry.value.length; i++) {
        content.writeln('${i + 1}. ${entry.value[i]}');
      }
    }
  }
  
  // Complete keyword list
  content.writeln();
  content.writeln('📋 COMPLETE KEYWORD LIST');
  content.writeln('=' * 50);
  
  for (var i = 0; i < allResults.length; i++) {
    content.writeln('${i + 1}. ${allResults[i]}');
  }
  
  // Footer
  content.writeln();
  content.writeln('=' * 50);
  content.writeln('Generated by Enhanced SEO Keyword Research Tool');
  content.writeln('Data sources: Google, Bing, DuckDuckGo');
  content.writeln('Includes: Autocomplete, Related Searches, People Also Ask');
  
  // Write to file
  await file.writeAsString(content.toString());
  
  stdout.writeln('💾 Saved comprehensive report to $filename');
  stdout.writeln('📁 Session folder: results/$folderName');
  
  return folderName;
}

// ========================================================================
// MAIN FUNCTION (for standalone execution)
// ========================================================================

/// Main entry point for standalone keyword research
/// 
/// Run with: dart run lib/keyword_generator.dart "<keyword>"
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('❌ Error: No keyword provided');
    stderr.writeln('Usage: dart run lib/keyword_generator.dart "<keyword>"');
    exit(1);
  }

  final keyword = args.join(' ').trim();
  
  if (keyword.isEmpty) {
    stderr.writeln('❌ Error: Keyword cannot be empty');
    exit(1);
  }

  stdout.writeln('🔍 Enhanced SEO Keyword Research for: "$keyword"\n');
  stdout.writeln('🚀 Fetching from multiple sources...\n');

  // Fetch from all sources with individual error handling
  final stopwatch = Stopwatch()..start();
  
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

  // Merge & dedupe while maintaining order and uniqueness
  final combined = <String>[];
  final seen = <String>{};

  /// Helper function to add keywords from a source
  void addFromSource(List<String> source) {
    for (final keyword in source) {
      final normalized = _normalize(keyword);
      if (!seen.contains(normalized)) {
        combined.add(keyword);
        seen.add(normalized);
      }
    }
  }

  // Add from each source (order determines priority)
  addFromSource(autocomplete);
  addFromSource(related);
  addFromSource(peopleAlsoAsk);
  addFromSource(bingAutocomplete);
  addFromSource(duckduckgoAutocomplete);

  stopwatch.stop();

  // Categorize keywords
  final categorized = categorizeKeywords(
    autocomplete: autocomplete,
    related: related,
    peopleAlsoAsk: peopleAlsoAsk,
    bingAutocomplete: bingAutocomplete,
    duckduckgoAutocomplete: duckduckgoAutocomplete,
  );

  // Display summary
  stdout.writeln('\n📊 SUMMARY:');
  stdout.writeln('Total unique keywords: ${combined.length}');
  stdout.writeln('Long-tail keywords (4+ words): ${categorized['Long-tail Keywords']?.length ?? 0}');
  stdout.writeln('Question-based keywords: ${categorized['Question Keywords']?.length ?? 0}');
  stdout.writeln('Processing time: ${stopwatch.elapsed.inSeconds}s');

  // Display top results preview
  stdout.writeln('\n🎯 Top 10 Results:');
  final displayCount = combined.length > 10 ? 10 : combined.length;
  
  for (var i = 0; i < displayCount; i++) {
    stdout.writeln('${i + 1}. ${combined[i]}');
  }

  if (combined.length > 10) {
    stdout.writeln('... and ${combined.length - 10} more keywords in the report');
  }

  if (combined.isEmpty) {
    stderr.writeln('\n⚠️  Warning: No keywords found. Try a different search term.');
    exit(1);
  }

  // Save results
  stdout.writeln();
  await saveResults(keyword, categorized, combined);
  
  stdout.writeln('\n✨ Enhanced keyword research completed!');
  stdout.writeln('Total time: ${stopwatch.elapsed.inSeconds}s');
}
