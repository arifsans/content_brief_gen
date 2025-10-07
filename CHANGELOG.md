# Changelog

All notable changes to the Enhanced SEO Tool will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-10-07

### 🎉 Major Release - Anthropic Claude Integration & Batch Processing

### Added
- **Anthropic Claude API Integration** - Migrated from OpenAI to Anthropic Claude 3 Haiku
- **Message Batches Support** - 50% cost reduction through batch processing
- **Enhanced Command Line Interface** - Added `--batch` flag for cost-efficient processing
- **Comprehensive Error Handling** - Graceful degradation and automatic fallbacks
- **SSL Certificate Fix** - Resolved DuckDuckGo handshake errors
- **Batch Result Management** - Organized batch summaries and individual file exports
- **Improved Documentation** - Complete README with usage examples and troubleshooting

### Changed
- **API Provider** - Switched from OpenAI GPT to Anthropic Claude for better content quality
- **Cost Structure** - Reduced API costs by up to 50% with batch processing option
- **Error Handling** - Silent handling of network errors without disrupting workflow
- **Configuration** - Updated API key format to support Anthropic (sk-ant- prefix)
- **Output Organization** - Enhanced folder structure with batch processing results

### Fixed
- **SSL Handshake Errors** - Resolved certificate verification issues with DuckDuckGo
- **Network Timeout Handling** - Better retry logic and graceful degradation
- **API Rate Limiting** - Improved delay mechanisms to prevent API overload
- **File Path Issues** - Robust file handling across different operating systems

### Deprecated
- **OpenAI Integration** - Removed OpenAI GPT support in favor of Anthropic Claude

## [1.5.0] - 2025-10-06

### Added
- **Word Document Export** - Microsoft Word format (.docx) for content briefs
- **Enhanced Report Generation** - Professional formatting and better organization
- **Multiple Export Formats** - TXT, JSON, and Word document support

### Improved
- **Keyword Categorization** - Better organization of keyword types
- **Content Brief Quality** - More detailed article structures and meta descriptions

## [1.4.0] - 2025-10-05

### Added
- **People Also Ask Integration** - Question-based keyword extraction from Google
- **Enhanced User Agent Rotation** - Better anti-detection mechanisms
- **Improved Error Messages** - More informative and actionable error reporting

### Fixed
- **Google Related Searches** - Improved parsing reliability
- **Timeout Handling** - Better connection timeout management

## [1.3.0] - 2025-10-04

### Added
- **Bing Autocomplete Support** - Additional keyword source for diversity
- **DuckDuckGo Integration** - Privacy-focused search engine data
- **Source Attribution** - Track where each keyword originated

### Improved
- **Keyword Deduplication** - Smart normalization and duplicate removal
- **Performance Optimization** - Faster concurrent API calls

## [1.2.0] - 2025-10-03

### Added
- **Content Brief Generation** - AI-powered SEO content brief creation
- **OpenAI Integration** - GPT-3.5-turbo for natural language generation
- **Structured Output** - JSON and text format exports

### Features
- SEO-optimized title generation
- Meta description creation
- Article structure outlining
- Related keyword integration

## [1.1.0] - 2025-10-02

### Added
- **Google Related Searches** - Extract "People also search for" keywords
- **Enhanced Keyword Research** - Multiple Google data sources
- **Categorized Results** - Organize keywords by type and source

### Improved
- **Report Generation** - Better formatted keyword research reports
- **Error Handling** - More robust network error management

## [1.0.0] - 2025-10-01

### Initial Release

### Added
- **Google Autocomplete** - Basic keyword suggestion extraction
- **Command Line Interface** - Simple Dart CLI tool
- **Keyword Export** - Text file output with timestamp
- **Basic Error Handling** - Network timeout and error management

### Features
- Single keyword input processing
- Google search suggestion extraction
- File-based result storage
- Cross-platform Dart implementation

---

## Legend

- 🎉 **Major Release** - Significant new features or breaking changes
- ✨ **Added** - New features and capabilities
- 🔄 **Changed** - Changes in existing functionality
- 🐛 **Fixed** - Bug fixes and error corrections
- ❌ **Deprecated** - Features marked for removal
- 🗑️ **Removed** - Deleted features or functionality

## Upgrade Notes

### From 1.x to 2.0.0
1. **API Key Change Required** - Update from OpenAI to Anthropic API key
2. **New Command Options** - Use `--batch` for cost-efficient processing
3. **Configuration Update** - Update config.json format for Anthropic

### Migration Steps
```bash
# 1. Update API key format
# Old: OPENAI_API_KEY=sk-proj-...
# New: ANTHROPIC_API_KEY=sk-ant-...

# 2. Update dependencies
dart pub get

# 3. Test new functionality
dart run enhanced_seo_tool.dart "test" --brief --batch
```