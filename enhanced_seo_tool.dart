import 'dart:io';
import 'dart:convert';
import 'bin/content_brief_gen.dart' as keyword_research;
import 'lib/content_brief_generator.dart';
import 'lib/word_document_generator.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run enhanced_seo_tool.dart "<keyword>" [--brief] [--batch]');
    print('');
    print('Options:');
    print('  --brief    Generate SEO content briefs for top keywords');
    print('  --batch    Use batch processing for multiple content briefs (50% cost savings)');
    print('');
    print('Examples:');
    print('  dart run enhanced_seo_tool.dart "cara membuat kopi"');
    print('  dart run enhanced_seo_tool.dart "cara membuat kopi" --brief');
    print('  dart run enhanced_seo_tool.dart "cara membuat kopi" --brief --batch');
    print('  dart run enhanced_seo_tool.dart "bisnis online" --brief');
    exit(1);
  }

  final generateBriefs = args.contains('--brief');
  final useBatch = args.contains('--batch');
  final keyword = args.where((arg) => !arg.startsWith('--')).join(' ').trim();

  print('🚀 Enhanced SEO Research & Content Brief Generator');
  print('${'=' * 55}');
  print('Target Keyword: "$keyword"');
  if (generateBriefs) {
    if (useBatch) {
      print('Mode: Keyword Research + Batch Content Brief Generation (50% cost savings)');
    } else {
      print('Mode: Keyword Research + Content Brief Generation');
    }
  } else {
    print('Mode: Keyword Research Only');
  }
  print('');

  try {
    // Step 1: Run keyword research
    print('📊 PHASE 1: KEYWORD RESEARCH');
    print('-' * 35);
    
    // We'll need to refactor the main function from content_brief_gen.dart
    // to return the results instead of just printing them
    final keywordResults = await runKeywordResearch(keyword);
    
    print('\n✅ Keyword research completed!');
    print('Found ${keywordResults['total']} unique keywords');

    if (!generateBriefs) {
      print('\n🎉 Process completed! Check the results folder for your keyword research report.');
      return;
    }

    // Step 2: Generate content briefs
    print('\n🤖 PHASE 2: CONTENT BRIEF GENERATION');
    print('-' * 40);

    // Get Anthropic API key
    final apiKey = await getAnthropicApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      print('❌ Anthropic API key not found!');
      print('Please set your API key in one of these ways:');
      print('1. Environment variable: ANTHROPIC_API_KEY=your_key_here');
      print('2. Create .env file with: ANTHROPIC_API_KEY=your_key_here');
      print('3. Create config.json with: {"anthropic_api_key": "your_key_here"}');
      exit(1);
    }

    final briefGenerator = ContentBriefGenerator(apiKey: apiKey);
    final wordGenerator = WordDocumentGenerator();

    // Generate briefs for top keywords
    final topKeywords = (keywordResults['combined'] as List<String>).take(5).toList();
    final relatedKeywords = (keywordResults['combined'] as List<String>).skip(5).take(15).toList();

    if (useBatch) {
      print('🚀 Using batch processing for ${topKeywords.length} keywords (50% cost savings)...\n');
      
      try {
        // Generate all briefs using batch processing
        final briefs = await briefGenerator.generateContentBriefsBatch(
          topKeywords,
          relatedKeywords,
        );

        // Save all batch results
        await briefGenerator.saveBatchContentBriefs(briefs);
        
        // Generate Word documents for each brief
        final wordGenerator = WordDocumentGenerator();
        for (final brief in briefs) {
          await wordGenerator.generateWordDocument(brief);
        }
        
        print('✅ Batch processing completed for ${briefs.length} keywords!\n');
        
      } catch (e) {
        print('❌ Error in batch processing: $e');
        print('💡 Falling back to individual processing...\n');
        
        // Fallback to individual processing
        await _processIndividualBriefs(briefGenerator, wordGenerator, topKeywords, relatedKeywords);
      }
    } else {
      print('🎯 Generating content briefs individually for ${topKeywords.length} keywords...\n');
      await _processIndividualBriefs(briefGenerator, wordGenerator, topKeywords, relatedKeywords);
    }

    print('🎉 ALL PROCESSES COMPLETED!');
    print('📁 Check these folders for your results:');
    print('  • results/ - Keyword research reports');
    print('  • content_briefs/ - SEO content briefs');
    print('');
    print('📄 Generated files for each keyword:');
    print('  • .txt - Human-readable content brief');
    print('  • .json - Machine-readable data');
    print('  • .docx - Microsoft Word document');

  } catch (e) {
    print('❌ An error occurred: $e');
    exit(1);
  }
}

/// Run keyword research and return results
Future<Map<String, dynamic>> runKeywordResearch(String keyword) async {
  // Import the functions from the original file
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

  // Save keyword research results
  await keyword_research.saveResults(keyword, categorized, combined);

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
  };
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

Future<void> _processIndividualBriefs(
  ContentBriefGenerator briefGenerator,
  WordDocumentGenerator wordGenerator,
  List<String> topKeywords,
  List<String> relatedKeywords,
) async {
  for (var i = 0; i < topKeywords.length; i++) {
    final currentKeyword = topKeywords[i];
    print('📝 [${i + 1}/${topKeywords.length}] Processing: "$currentKeyword"');
    
    try {
      // Generate content brief
      final brief = await briefGenerator.generateContentBrief(
        currentKeyword,
        relatedKeywords,
      );

      // Save as text file
      await briefGenerator.saveContentBrief(brief);
      
      // Save as JSON
      await briefGenerator.saveContentBriefAsJson(brief);
      
      // Save as Word document
      await wordGenerator.generateWordDocument(brief);
      
      print('✅ Brief completed for: "$currentKeyword"\n');
      
      // Small delay to avoid rate limiting
      await Future.delayed(Duration(seconds: 2));
      
    } catch (e) {
      print('❌ Error generating brief for "$currentKeyword": $e\n');
      continue;
    }
  }
}