import 'dart:io';
import 'dart:convert';
import 'lib/keyword_generator.dart' as keyword_research;
import 'lib/ai_provider.dart';
import 'lib/optimized_content_brief_generator.dart';
import 'lib/gemini_content_brief_generator.dart';
import 'lib/word_document_generator.dart';
import 'lib/article_title_generator.dart';
import 'lib/gemini_article_title_generator.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run enhanced_seo_tool.dart "<keyword>" [--brief] [--provider=<anthropic|gemini>]');
    print('');
    print('Options:');
    print('  --brief            Generate SEO content briefs with AI-powered title selection');
    print('  --provider=<name>  Choose AI provider: anthropic (default) or gemini');
    print('');
    print('Flow with --brief:');
    print('  1. Keyword research from multiple sources');
    print('  2. AI generates SEO-friendly article titles (excluding brands)');
    print('  3. User selects a title or inputs custom title');
    print('  4. Generate comprehensive content brief (optimized with auto-fallback)');
    print('');
    print('Examples:');
    print('  dart run enhanced_seo_tool.dart "cara membuat kopi"');
    print('  dart run enhanced_seo_tool.dart "cara membuat kopi" --brief');
    print('  dart run enhanced_seo_tool.dart "bisnis online" --brief --provider=gemini');
    print('  dart run enhanced_seo_tool.dart "urutan skincare" --brief --provider=anthropic');
    exit(1);
  }

  final generateBriefs = args.contains('--brief');
  
  // Parse provider argument
  AIProvider provider = AIProvider.anthropic; // default
  for (final arg in args) {
    if (arg.startsWith('--provider=')) {
      final providerName = arg.substring('--provider='.length).toLowerCase();
      if (providerName == 'gemini') {
        provider = AIProvider.gemini;
      } else if (providerName == 'anthropic') {
        provider = AIProvider.anthropic;
      } else {
        print('❌ Invalid provider: $providerName. Use "anthropic" or "gemini".');
        exit(1);
      }
    }
  }
  
  final keyword = args.where((arg) => !arg.startsWith('--')).join(' ').trim();

  print('🚀 Enhanced SEO Research & Content Brief Generator');
  print('${'=' * 55}');
  print('Target Keyword: "$keyword"');
  print('AI Provider: ${provider == AIProvider.anthropic ? 'Anthropic Claude' : 'Google Gemini'}');
  if (generateBriefs) {
    print('Mode: Keyword Research → AI Title Generation → User Selection → Content Brief (Optimized)');
  } else {
    print('Mode: Keyword Research Only');
  }
  print('');

  try {
    // Step 1: Run keyword research
    if (generateBriefs) {
      print('📊 PHASE 1: KEYWORD RESEARCH');
    }
    
    print('-' * 35);
    
    final keywordResults = await runKeywordResearch(keyword);
    
    print('\n✅ Keyword research completed!');
    print('Found ${keywordResults['total']} unique keywords');

    if (!generateBriefs) {
      print('\n🎉 Process completed! Check the results folder for your keyword research report.');
      return;
    }

    // Get API key based on provider
    final apiKey = await getApiKey(provider);
    if (apiKey == null || apiKey.isEmpty) {
      print('❌ ${provider == AIProvider.anthropic ? 'Anthropic' : 'Google Gemini'} API key not found!');
      print('Please set your API key in one of these ways:');
      if (provider == AIProvider.anthropic) {
        print('1. Environment variable: ANTHROPIC_API_KEY=your_key_here');
        print('2. Create .env file with: ANTHROPIC_API_KEY=your_key_here');
        print('3. Create config.json with: {"anthropic_api_key": "your_key_here"}');
      } else {
        print('1. Environment variable: GEMINI_API_KEY=your_key_here');
        print('2. Create .env file with: GEMINI_API_KEY=your_key_here');
        print('3. Create config.json with: {"gemini_api_key": "your_key_here"}');
      }
      exit(1);
    }

    // Step 1.5: Generate SEO-friendly article titles
    print('\n📝 PHASE 1.5: GENERATING SEO-FRIENDLY ARTICLE TITLES');
    print('-' * 55);
    
    final allKeywords = keywordResults['combined'] as List<String>;
    
    // Create title generator based on provider
    late AIArticleTitleGenerator titleGenerator;
    if (provider == AIProvider.anthropic) {
      titleGenerator = ArticleTitleGenerator(apiKey: apiKey);
    } else {
      titleGenerator = GeminiArticleTitleGenerator(apiKey: apiKey);
    }
    
    final generatedTitles = await titleGenerator.generateArticleTitles(allKeywords);
    
    print('✨ Generated ${generatedTitles.length} SEO-friendly article titles:\n');
    for (int i = 0; i < generatedTitles.length; i++) {
      print('${i + 1}. ${generatedTitles[i]}');
    }
    
    // Step 1.6: User selects or inputs a title
    print('\n📌 SELECT AN ARTICLE TITLE');
    print('-' * 35);
    print('Choose one of the generated titles (1-${generatedTitles.length}), or enter 0 to input your own title:');
    
    final selectedTitle = await getUserSelectedTitle(generatedTitles);
    print('\n✅ Selected title: "$selectedTitle"');

    // Step 2: Generate content brief for the selected title
    print('\n🤖 PHASE 2: CONTENT BRIEF GENERATION');
    print('-' * 40);
    print('🚀 Using Optimized Unified Generation with Auto-Fallback...');
    print('💡 Single API call + Retry mechanism + Rate limiting\n');

    // Create brief generator based on provider
    late AIContentBriefGenerator briefGenerator;
    if (provider == AIProvider.anthropic) {
      briefGenerator = OptimizedContentBriefGenerator(apiKey: apiKey);
    } else {
      briefGenerator = GeminiContentBriefGenerator(apiKey: apiKey);
    }
    
    final wordGenerator = WordDocumentGenerator();

    // Use the selected title as the keyword for brief generation
    final targetKeyword = selectedTitle;
    final timestampedFolder = keywordResults['timestampedFolder'] as String;

    try {
      // Generate content brief (unified generation - 1 API call)
      // Not passing relatedKeywords to avoid brand contamination
      final brief = await briefGenerator.generateContentBrief(
        targetKeyword,
        [], // Empty list - AI will generate relevant keywords without brand bias
      );

      // Save content brief (includes TXT and JSON)
      await briefGenerator.saveContentBrief(
        brief, 
        timestampedFolder: timestampedFolder
      );
      
      // Generate Word document
      await wordGenerator.generateWordDocument(
        brief, 
        timestampedFolder: timestampedFolder
      );
      print('📄 Word document saved for: "${brief.keyword}"');
      
      print('\n✅ Content brief generation completed!\n');
      
    } catch (e) {
      print('❌ Error in content brief generation: $e');
      print('💡 All retry attempts exhausted. Please check your API key and network connection.');
      exit(1);
    }
    
    // Print combined performance metrics
    if (provider == AIProvider.anthropic) {
      OptimizedContentBriefGenerator.printCombinedMetrics(
        keywordMetrics: keyword_research.keywordMetrics.getSummary(),
        briefMetrics: briefGenerator.getMetrics(),
      );
    } else {
      // For Gemini, print metrics separately (no static method needed)
      print('\n' + '=' * 60);
      print('📊 COMBINED WORKFLOW METRICS');
      print('=' * 60);
      
      final keywordMetrics = keyword_research.keywordMetrics.getSummary();
      print('\n🔍 KEYWORD RESEARCH PHASE:');
      print('   API calls: ${keywordMetrics['total_api_calls']}');
      print('   Success rate: ${keywordMetrics['success_rate_percent']}%');
      print('   Keywords found: ${keywordMetrics['total_keywords_found']}');
      print('   Avg latency: ${keywordMetrics['avg_latency_ms']}ms');
      
      briefGenerator.printMetrics();
      print('=' * 60);
    }

    print('\n🎉 ALL PROCESSES COMPLETED!');
    print('📁 All results saved to: results/$timestampedFolder');
    print('');
    print('📄 Generated files in this session:');
    print('  • keyword_research_report.txt - Comprehensive keyword analysis');
    print('  • ${targetKeyword.replaceAll(' ', '_').toLowerCase()}_content_brief.txt - Human-readable content brief');
    print('  • ${targetKeyword.replaceAll(' ', '_').toLowerCase()}_content_brief.json - Machine-readable data');
    print('  • ${targetKeyword.replaceAll(' ', '_').toLowerCase()}_brief.docx - Microsoft Word document');
    print('');
    print('💡 Process flow completed:');
    print('  ✅ Step 1: Keyword research from multiple sources');
    print('  ✅ Step 2: AI-generated SEO-friendly article titles (${provider == AIProvider.anthropic ? 'Claude' : 'Gemini'})');
    print('  ✅ Step 3: User selected article title');
    print('  ✅ Step 4: Generated comprehensive content brief (${provider == AIProvider.anthropic ? 'Claude' : 'Gemini'})');
    print('');
    print('⚡ AI Provider: ${provider == AIProvider.anthropic ? 'Anthropic Claude Sonnet 4' : 'Google Gemini 2.0 Flash'}');

  } catch (e) {
    print('\n❌ An error occurred: $e');
    exit(1);
  }
}

/// Run keyword research and return results
Future<Map<String, dynamic>> runKeywordResearch(String keyword) async {
  final autocomplete = await keyword_research.fetchAutocomplete(keyword);
  print('✅ Google Autocomplete: ${autocomplete.length} results');

  final related = await keyword_research.fetchRelatedSearches(keyword);
  print('✅ Google Related Searches: ${related.length} results');

  final peopleAlsoAsk = await keyword_research.fetchPeopleAlsoAsk(keyword);
  print('✅ People Also Ask: ${peopleAlsoAsk.length} results');

  final bingAutocomplete = await keyword_research.fetchBingAutocomplete(keyword);
  print('✅ Bing Autocomplete: ${bingAutocomplete.length} results');

  final duckduckgoAutocomplete = await keyword_research.fetchDuckDuckGoAutocomplete(keyword);
  print('✅ DuckDuckGo Autocomplete: ${duckduckgoAutocomplete.length} results');

  // Merge & dedupe
  final combined = <String>[];
  final seen = <String>{};

  // Add from each source while maintaining uniqueness
  for (var s in autocomplete) {
    final n = keyword_research.normalize(s);
    if (!seen.contains(n)) {
      combined.add(s);
      seen.add(n);
    }
  }
  for (var s in related) {
    final n = keyword_research.normalize(s);
    if (!seen.contains(n)) {
      combined.add(s);
      seen.add(n);
    }
  }
  for (var s in peopleAlsoAsk) {
    final n = keyword_research.normalize(s);
    if (!seen.contains(n)) {
      combined.add(s);
      seen.add(n);
    }
  }
  for (var s in bingAutocomplete) {
    final n = keyword_research.normalize(s);
    if (!seen.contains(n)) {
      combined.add(s);
      seen.add(n);
    }
  }
  for (var s in duckduckgoAutocomplete) {
    final n = keyword_research.normalize(s);
    if (!seen.contains(n)) {
      combined.add(s);
      seen.add(n);
    }
  }

  // Categorize keywords
  final categorized = keyword_research.categorizeKeywords(
    autocomplete: autocomplete,
    related: related,
    peopleAlsoAsk: peopleAlsoAsk,
    bingAutocomplete: bingAutocomplete,
    duckduckgoAutocomplete: duckduckgoAutocomplete,
  );

  // Save keyword research results and get the timestamped folder name
  final timestampedFolder = await keyword_research.saveResults(keyword, categorized, combined);

  return {
    'keyword': keyword,
    'total': combined.length,
    'combined': combined,
    'categorized': categorized,
    'autocomplete': autocomplete,
    'related': related,
    'peopleAlsoAsk': peopleAlsoAsk,
    'bingAutocomplete': bingAutocomplete,
    'duckduckgoAutocomplete': duckduckgoAutocomplete,
    'timestampedFolder': timestampedFolder,
  };
}

Future<String?> getApiKey(AIProvider provider) async {
  final envVarName = provider == AIProvider.anthropic ? 'ANTHROPIC_API_KEY' : 'GEMINI_API_KEY';
  final configKeyName = provider == AIProvider.anthropic ? 'anthropic_api_key' : 'gemini_api_key';
  
  // Try environment variable first
  final envKey = Platform.environment[envVarName];
  if (envKey != null && envKey.isNotEmpty) {
    return envKey;
  }

  // Try .env file
  final envFile = File('.env');
  if (await envFile.exists()) {
    final content = await envFile.readAsString();
    final lines = content.split('\n');
    for (final line in lines) {
      if (line.startsWith('$envVarName=')) {
        final key = line.substring('$envVarName='.length).trim();
        if (key.isNotEmpty) return key;
      }
    }
  }

  // Try config.json file
  final configFile = File('config.json');
  if (await configFile.exists()) {
    try {
      final content = await configFile.readAsString();
      final config = jsonDecode(content) as Map<String, dynamic>;
      final key = config[configKeyName] as String?;
      if (key != null && key.isNotEmpty) return key;
    } catch (e) {
      print('Error reading config.json: $e');
    }
  }

  return null;
}

Future<String?> getAnthropicApiKey() async {
  // Try environment variable first
  final envKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (envKey != null && envKey.isNotEmpty) {
    return envKey;
  }

  // Try .env file
  final envFile = File('.env');
  if (await envFile.exists()) {
    final content = await envFile.readAsString();
    final lines = content.split('\n');
    for (final line in lines) {
      if (line.startsWith('ANTHROPIC_API_KEY=')) {
        final key = line.substring('ANTHROPIC_API_KEY='.length).trim();
        if (key.isNotEmpty) return key;
      }
    }
  }

  // Try config.json file
  final configFile = File('config.json');
  if (await configFile.exists()) {
    try {
      final content = await configFile.readAsString();
      final config = jsonDecode(content) as Map<String, dynamic>;
      final key = config['anthropic_api_key'] as String?;
      if (key != null && key.isNotEmpty) return key;
    } catch (e) {
      print('Error reading config.json: $e');
    }
  }

  return null;
}

/// Get user's selected title from generated list or allow manual input
Future<String> getUserSelectedTitle(List<String> titles) async {
  if (titles.isEmpty) {
    print('⚠️ No titles generated. Please enter your article title manually:');
    return stdin.readLineSync()?.trim() ?? '';
  }
  
  while (true) {
    stdout.write('\nYour choice (0-${titles.length}): ');
    final input = stdin.readLineSync()?.trim();
    
    if (input == null || input.isEmpty) {
      print('❌ Invalid input. Please try again.');
      continue;
    }
    
    final choice = int.tryParse(input);
    
    if (choice == null) {
      print('❌ Please enter a valid number.');
      continue;
    }
    
    if (choice == 0) {
      print('\n✏️ Enter your custom article title:');
      stdout.write('Title: ');
      final customTitle = stdin.readLineSync()?.trim();
      if (customTitle != null && customTitle.isNotEmpty) {
        return customTitle;
      } else {
        print('❌ Title cannot be empty. Please try again.');
        continue;
      }
    }
    
    if (choice >= 1 && choice <= titles.length) {
      return titles[choice - 1];
    }
    
    print('❌ Invalid choice. Please select a number between 0 and ${titles.length}.');
  }
}
