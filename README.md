# 🚀 Enhanced SEO Tool - Advanced Keyword Research & AI Content Brief Generator

A comprehensive, professional-grade SEO tool that combines multi-source keyword research with AI-powered content brief generation and **full article generation** using **Anthropic Claude** or **Google Gemini**. Features **dual AI provider support**, **AI title generation**, **full SEO article generation**, **Word document export**, **brand-free keyword filtering**, **optimized unified generation**, and **Indonesian language support** for scalable content creation.

## 🆕 What's New in v3.4

🔧 **Word Document Fix** - Fixed "List 1" error in generated Word documents
📏 **Article Length Control** - Strict 1000-2000 word limit (was 4000+)
💰 **50% Cost Reduction** - Reduced from 4000+ words to 2000 words max
📚 **SEO-Friendly Sources** - Natural source references instead of bibliography format
🌐 **WordPress HTML Export** - Copy-paste ready HTML for WordPress Block Editor
✨ **Block Editor Compatible** - Uses `<b>` and `<i>` tags for perfect rendering
✨ **Better Quality** - More focused, concise, and cost-effective articles

## Previous Updates (v3.3)

🎯 **Full Article Generation** - Generate complete 1000-2000 word SEO-optimized articles!
📝 **Structured Content** - Articles follow your content brief exactly
🌐 **Page One Optimization** - Content designed to rank on Google page one
✨ **Dual AI Support** - Available with both Claude and Gemini
💡 **Optional Feature** - Choose whether to generate article or just brief

🎮 **Interactive Input Mode** - No more complex command-line arguments!
✨ **Dual AI Provider Support** - Choose between Anthropic Claude or Google Gemini
💰 **97.9% Cost Savings** - Use Gemini at $0.000225 per brief vs Claude at $0.0105
⚡ **Faster Generation** - Gemini delivers results in 1-2 seconds
🎯 **Guided Workflow** - The tool prompts you step-by-step

## 📖 Table of Contents

- [Quick Start](#-quick-start)
- [Features](#-features)
- [Setup & Installation](#-setup--installation)
- [Usage Guide](#-usage-guide)
- [AI Provider Comparison](#ai-provider-comparison)
- [Output Examples](#-output-examples)
- [Performance & Cost Analysis](#-performance--cost-analysis)
- [Best Practices](#-best-practices)
- [Troubleshooting](#-troubleshooting)
- [Recent Updates](#-recent-updates)

## ⚡ Quick Commands Reference

```bash
# Simple! Just run the tool and follow the interactive prompts:
dart run enhanced_seo_tool.dart

# Or use the compiled executable (3-5x faster):
./seo-tool

# Get your API keys:
# Gemini: https://aistudio.google.com/app/apikey
# Claude: https://console.anthropic.com/settings/keys
```

## 🚀 Quick Start

```bash
# 1. Install dependencies
dart pub get

# 2. Set API key (choose your provider)
# For Anthropic Claude
export ANTHROPIC_API_KEY="sk-ant-your_key_here"

# OR for Google Gemini (97.9% cheaper!)
export GEMINI_API_KEY="your_gemini_key_here"

# 3. Compile to executable (optional but recommended for speed)
./compile.sh

# 4. Run the tool - it will guide you through!
./seo-tool

# OR use Dart directly
dart run enhanced_seo_tool.dart
```

**🎯 Interactive Flow:**
1. Enter your target keyword
2. Choose: Full workflow or Keyword Research only
3. Select AI Provider: Gemini (faster & cheaper) or Claude (premium)

**🎯 Provider Recommendations:**
- Use **Gemini** for: Cost-effectiveness, high-volume generation, testing
- Use **Claude** for: Premium quality, complex reasoning, critical content

**Pro Tip**: Use the compiled executable (`./seo-tool`) for 3-5x faster startup time! See [Executable Management](#-executable-management) section below.

## ✨ Features

### 🔍 **Multi-Source Keyword Research**
- **Google Autocomplete** - Real-time search suggestions with user intent analysis
- **Google Related Searches** - Bottom page suggestions and semantic keywords
- **People Also Ask** - Question-based keywords for FAQ optimization
- **Bing Autocomplete** - Microsoft search engine diversity and alternative perspectives
- **DuckDuckGo Autocomplete** - Privacy-focused search engine data with SSL error handling

### 🤖 **AI-Powered Content Brief Generation (Indonesian Language)**
- **Interactive Input Mode** - Guided step-by-step workflow without complex arguments
- **Dual AI Provider Support** - Choose between Anthropic Claude or Google Gemini interactively
- **Anthropic Claude Integration** - Premium AI using Claude Haiku 4.5 for highest quality content
- **Google Gemini Integration** - Cost-effective AI using Gemini 1.5 Flash (91.9% cheaper)
- **Easy Provider Selection** - Simple number input to choose your AI provider
- **AI Title Generation** - Generates 5-10 SEO-friendly article titles with automatic brand filtering
- **Interactive Title Selection** - Choose from AI-generated titles or input your own custom title  
- **Brand-Free Keywords** - AI automatically generates 10-15 related keywords without brand contamination
- **Unified Generation** - Single API call for complete content brief (54% cost savings vs 4 separate calls)
- **Auto-Retry with Fallback** - Exponential backoff retry + fallback to individual generation for 99% reliability
- **SEO-Optimized Titles** - Character-limited, keyword-focused H1 titles (50-60 chars)
- **Meta Descriptions** - Compelling, click-through optimized descriptions (150-160 chars)
- **Article Structure** - Detailed H2/H3 outline with 6-8 main sections
- **Topic Analysis** - Comprehensive topic recommendations with user intent focus

### 📝 **NEW: Full Article Generation**
- **Complete Articles** - Generate 1000-2000 word SEO-optimized articles
- **Strict Word Limits** - 1000 word minimum, 2000 word maximum (controlled length)
- **Brief-Based** - Articles follow your content brief structure exactly
- **SEO Optimized** - Keyword density, E-E-A-T principles, readability optimization
- **Natural Language** - Conversational Bahasa Indonesia content
- **SEO-Friendly Sources** - Natural source references (not bibliography format)
- **Multiple Formats** - Markdown (.md) and Word Document (.docx) exports
- **Optional Feature** - Choose whether to generate article after brief creation
- **Page One Targeting** - Content designed to rank on Google page one
- **Both AI Providers** - Available with Claude (premium) or Gemini (cost-effective)
- **Metadata Tracking** - Word count, character count, generation details
- **Cost Effective** - 50% cost reduction due to shorter, focused articles

### 💰 **Cost Optimization Features**
- **Unified Generation** - Generate all components in 1 API call instead of 4 (54% cost savings)
- **Optimized Prompts** - 300 tokens vs 900 tokens (67% token reduction)
- **Auto-Retry Mechanism** - Exponential backoff with 3 max retries for reliability
- **Rate Limiting Protection** - 500ms minimum delay between requests to prevent API errors
- **Performance Metrics** - Real-time tracking of success rate, latency, and cost per brief

### 🇮🇩 **Indonesian Language Support**
- **Native Indonesian Prompts** - Expert SEO copywriter personas in Indonesian
- **Indonesian Content Guidelines** - Comprehensive SEO best practices adapted for Indonesian market
- **Indonesian Output** - All content briefs generated in natural Indonesian language
- **Cultural Adaptation** - SEO strategies tailored for Indonesian search behavior and preferences

### 📊 **Export & Organization**
- **Timestamped Folders** - Each execution creates organized session folders with timestamp
- **Multiple Formats** - TXT, JSON, and Microsoft Word documents
- **Organized Structure** - Automatic folder organization and file naming
- **Professional Reports** - Detailed keyword research with source attribution

## 🛠️ Setup & Installation

### 1. **Install Dart SDK**

This tool requires Dart SDK to run. Install it based on your operating system:

#### **macOS**
```bash
# Using Homebrew (recommended)
brew tap dart-lang/dart
brew install dart

# Verify installation
dart --version
```

#### **Windows**
```bash
# Using Chocolatey
choco install dart-sdk

# Or download installer from:
# https://dart.dev/get-dart

# Verify installation
dart --version
```

#### **Linux**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install apt-transport-https
sudo sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
sudo sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
sudo apt-get update
sudo apt-get install dart

# Verify installation
dart --version
```

For more installation options, visit: https://dart.dev/get-dart

### 2. **Install Project Dependencies**
```bash
# Clone or download the project
cd content_brief_gen

# Install Dart dependencies
dart pub get
```

### 3. **Set up AI Provider API Keys**

You can use either Anthropic Claude or Google Gemini (or both!).

#### **Option A: Google Gemini (Recommended - 97.9% Cheaper)**

Get your API key from [Google AI Studio](https://aistudio.google.com/app/apikey)

**Setup methods:**

**Environment Variable (Recommended)**
```bash
# Windows (PowerShell)
$env:GEMINI_API_KEY="your_gemini_api_key_here"

# Windows (Command Prompt)
set GEMINI_API_KEY=your_gemini_api_key_here

# Linux/macOS
export GEMINI_API_KEY="your_gemini_api_key_here"
```

**Option B: .env File**
```bash
echo "GEMINI_API_KEY=your_gemini_api_key_here" > .env
```

**Option C: config.json File**
```json
{
  "gemini_api_key": "your_gemini_api_key_here"
}
```

#### **Option B: Anthropic Claude (Premium Quality)**

Get your API key from [Anthropic Console](https://console.anthropic.com/settings/keys)

**Choose one setup method:**

**Environment Variable (Recommended)**
```bash
# Windows (PowerShell)
$env:ANTHROPIC_API_KEY="sk-ant-your_anthropic_api_key_here"

# Windows (Command Prompt)
set ANTHROPIC_API_KEY=sk-ant-your_anthropic_api_key_here

# Linux/macOS
export ANTHROPIC_API_KEY="sk-ant-your_anthropic_api_key_here"
```

**Option B: .env File**
```bash
echo "ANTHROPIC_API_KEY=sk-ant-your_anthropic_api_key_here" > .env
```

**Option C: config.json File**
```json
{
  "anthropic_api_key": "sk-ant-your_anthropic_api_key_here",
  "gemini_api_key": "your_gemini_api_key_here"
}
```

**💡 Pro Tip**: Set up both API keys to switch between providers as needed!

### 4. **Verify Installation**
```bash
# Test keyword research (no API key needed)
dart run enhanced_seo_tool.dart "test keyword"

# Test with Gemini (requires Gemini API key)
dart run enhanced_seo_tool.dart "test keyword" --brief --provider=gemini

# Test with Claude (requires Anthropic API key)
dart run enhanced_seo_tool.dart "test keyword" --brief --provider=anthropic
```

### 5. **Create Executable (Optional but Recommended)**

For faster execution and easier usage, compile the tool to a native executable:

```bash
# Compile to executable
./compile.sh

# Or manually:
dart compile exe enhanced_seo_tool.dart -o seo-tool
```

**Benefits of using the executable:**
- ✅ 3-5x faster startup time
- ✅ No need to type `dart run` every time
- ✅ Can be installed globally for system-wide access
- ✅ Works without Dart SDK (portable)
- ✅ Easier to distribute to team members

**Install globally (optional):**
```bash
# macOS/Linux
sudo mv seo-tool /usr/local/bin/

# Now run from anywhere:
seo-tool "your keyword" --brief
```

See [EXECUTABLE_GUIDE.md](EXECUTABLE_GUIDE.md) for detailed instructions.

## 🎯 Usage Guide

### **How to Run the Tool**

The tool now uses **interactive input mode** instead of command-line arguments. Simply run:

```bash
# Using Dart (Development)
dart run enhanced_seo_tool.dart

# OR using compiled executable (Recommended - Faster)
./seo-tool
```

The tool will guide you through:
1. 📝 **Enter target keyword** - Type your keyword when prompted
2. 📋 **Choose workflow** - Select between:
   - Full workflow (Keyword Research → AI Title Generation → Content Brief)
   - Keyword Research Only
3. 🤖 **Select AI Provider** (if generating content brief):
   - Anthropic Claude (Premium quality)
   - Google Gemini (97.9% cheaper, faster)

### **Interactive Flow Example**

```bash
$ dart run enhanced_seo_tool.dart

🚀 Enhanced SEO Research & Content Brief Generator
=======================================================

📝 Enter your target keyword:
Keyword: cara membuat kopi

📋 Do you want to generate content brief?
1. Yes - Full workflow (Keyword Research → Title Generation → Content Brief)
2. No - Keyword Research Only

Your choice (1-2): 1

🤖 Select AI Provider:
1. Anthropic Claude (Default)
2. Google Gemini

Your choice (1-2): 2

🚀 Enhanced SEO Research & Content Brief Generator
=======================================================
Target Keyword: "cara membuat kopi"
AI Provider: Google Gemini
Mode: Keyword Research → AI Title Generation → User Selection → Content Brief (Optimized)

📊 PHASE 1: KEYWORD RESEARCH
-----------------------------------
...
```

### **Why Interactive Input?**
- ✅ **No need to remember commands** - The tool guides you step by step
- ✅ **Easier to use** - Just run the tool and follow prompts
- ✅ **Fewer typos** - No complex command-line arguments
- ✅ **Better UX** - Clear options at each step

### **Old Command-Line vs New Interactive**

**Before (Complex):**
```bash
dart run enhanced_seo_tool.dart "your keyword here" --brief --provider=gemini
```

**Now (Simple):**
```bash
dart run enhanced_seo_tool.dart
# Then follow the prompts!
```

### **New Enhanced Workflow**

When choosing the full workflow option (option 1), the tool follows an enhanced 4-step workflow:

1. **Keyword Research** - Gathers keywords from 5 different sources
2. **AI Title Generation** - Generates 5 SEO-friendly article titles (brand-free)
3. **User Selection** - Choose from generated titles or input custom title
4. **Content Brief Generation** - Creates comprehensive SEO brief with AI-generated brand-free keywords

This will:
- ✅ Research keywords from 5 sources
- ✅ Generate 5-10 SEO-optimized article titles
- ✅ Let you select or input your title
- ✅ Generate complete content brief with brand-free keywords

### **Practical Examples**

```bash
# Simply run the tool - it will prompt you for everything!
dart run enhanced_seo_tool.dart

# Or use the compiled executable (faster)
./seo-tool

# The tool will ask you to:
# 1. Enter keyword (e.g., "cara membuat kopi", "tips diet sehat")
# 2. Choose workflow (Full or Keyword Research only)
# 3. Select AI provider (Gemini or Claude)

# If installed globally, run from anywhere:
cd ~/Documents
./seo-tool
```
seo-tool "bisnis online pemula" --brief --provider=gemini
```

### **AI Provider Comparison**

| Feature | Anthropic Claude | Google Gemini |
|---------|-----------------|---------------|
| **Model** | Claude Haiku 4.5 | Gemini 1.5 Flash |
| **Speed** | Fast (~2-3s) | Ultra Fast (~1-2s) ⚡ |
| **Cost per Brief** | $0.0028 | $0.000225 💰 |
| **Cost Savings** | Baseline | **91.9% cheaper!** |
| **Quality** | Excellent ⭐⭐⭐⭐⭐ | Very Good ⭐⭐⭐⭐ |
| **Best For** | Premium content | High-volume generation |
| **Context Window** | 200k tokens | 128k tokens |

**💡 Recommendation**: Start with Gemini for cost-effectiveness, upgrade to Claude for premium content.

**Cost Example (100 briefs/month):**
- Claude: $0.0105 × 100 = **$1.05/month**
- Gemini: $0.000225 × 100 = **$0.0225/month**
- **Savings: $1.03/month (97.9%)**

### **Interactive Title Selection Example**

```bash
# Simply run the tool
$ ./seo-tool

# Or using Dart command
$ dart run enhanced_seo_tool.dart

🚀 Enhanced SEO Research & Content Brief Generator
=======================================================

📝 Enter your target keyword:
Keyword: cara merawat kulit wajah

📋 Do you want to generate content brief?
1. Yes - Full workflow (Keyword Research → Title Generation → Content Brief)
2. No - Keyword Research Only

Your choice (1-2): 1

🤖 Select AI Provider:
1. Anthropic Claude (Default)
2. Google Gemini

Your choice (1-2): 2

📝 PHASE 1.5: GENERATING SEO-FRIENDLY ARTICLE TITLES
-------------------------------------------------------
✨ Generated 5 SEO-friendly article titles:

1. Cara Merawat Kulit Wajah: Panduan Lengkap untuk Pemula
2. 10 Tips Merawat Kulit Wajah Agar Sehat dan Glowing
3. Cara Merawat Kulit Wajah Berdasarkan Jenis Kulit
4. Rutinitas Merawat Kulit Wajah Pagi dan Malam
5. Cara Merawat Kulit Wajah Secara Alami dan Efektif

📌 SELECT AN ARTICLE TITLE
-----------------------------------
Choose one of the generated titles (1-5), or enter 0 to input your own title:

Your choice (0-5): 2

✅ Selected title: "10 Tips Merawat Kulit Wajah Agar Sehat dan Glowing"

🤖 PHASE 2: CONTENT BRIEF GENERATION
----------------------------------------
🚀 Using Optimized Unified Generation with Auto-Fallback...
💡 Single API call + Retry mechanism + Rate limiting

✨ AI generated 15 brand-free related keywords
✅ Brief selesai dalam 4567ms
```

### **Command Options**

| Option | Description | Features | Use Case |
|--------|-------------|----------|----------|
| (none) | Keyword research only | Multi-source keyword discovery | Quick keyword research |
| `--brief` | Complete workflow with AI titles | AI titles + User selection + Brand-free keywords | Content planning & SEO brief creation |

### **💰 Cost Optimization Guide**

#### **Unified Generation Benefits**
- **Single API Call**: All components generated at once (vs 4 separate calls)
- **Cost Savings**: 54% reduction compared to individual component generation
- **Token Efficiency**: Optimized prompts (300 tokens vs 900 tokens) = 67% reduction
- **Reliability**: Auto-retry with exponential backoff + fallback mechanism

#### **Real-time Performance Tracking**
```
🚀 Membuat content brief untuk: "tips diet sehat"
✨ AI generated 15 brand-free related keywords
✅ Brief selesai dalam 4567ms

📊 STATISTIK PERFORMANCE:
   Total requests: 1
   Success rate: 100.0%
   Total cost: $0.0006
   Avg latency: 4567ms
```

#### **Optimal Usage Patterns**
- **Single keyword**: Use `--brief` for complete workflow
- **Multiple keywords**: Run separately for each topic
- **Client projects**: Process one keyword at a time for quality control

## � Executable Management

### **Creating the Executable**

The tool can be compiled into a standalone native executable for better performance:

```bash
# Quick compile
./compile.sh

# Or manual compilation
dart compile exe enhanced_seo_tool.dart -o seo-tool

# Verify the executable
./seo-tool "test" --brief
```

### **Installation Options**

#### **Local Usage (Current Directory)**
```bash
# Run from project directory
./seo-tool "your keyword" --brief
```

#### **Global Installation (System-wide Access)**
```bash
# macOS/Linux
sudo mv seo-tool /usr/local/bin/
# or
sudo cp seo-tool /usr/local/bin/

# Verify global installation
seo-tool --help

# Now use from anywhere
cd ~/Desktop
seo-tool "skincare routine" --brief
```

#### **Shell Script Wrapper (Development)**
```bash
# Use shell wrapper (requires Dart SDK)
./seo-tool.sh "keyword" --brief

# Create permanent alias
echo 'alias seo-tool="$HOME/path/to/content_brief_gen/seo-tool.sh"' >> ~/.zshrc
source ~/.zshrc
```

### **Updating After Code Changes**

When you modify the Dart code, recompile the executable:

```bash
# Recompile
./compile.sh

# If globally installed, update it
sudo cp seo-tool /usr/local/bin/
```

### **Distribution to Team Members**

Share the compiled executable with team members:

```bash
# Create distribution package
mkdir seo-tool-distribution
cp seo-tool seo-tool-distribution/
cp EXECUTABLE_GUIDE.md seo-tool-distribution/
cp README.md seo-tool-distribution/
cp config.json.example seo-tool-distribution/

# Compress for sharing
tar -czf seo-tool-macos.tar.gz seo-tool-distribution/

# Team members can extract and run without Dart SDK
tar -xzf seo-tool-macos.tar.gz
cd seo-tool-distribution
./seo-tool "keyword" --brief
```

### **Performance Comparison**

| Method | Startup Time | Requirements | Best For |
|--------|--------------|--------------|----------|
| `dart run` | ~2-3 seconds | Dart SDK | Development |
| `./seo-tool` | ~0.5 seconds | None | Production |
| Global `seo-tool` | ~0.5 seconds | None | Daily use |

### **Executable Benefits**

✅ **Performance**: 3-5x faster startup (no VM initialization)  
✅ **Portability**: Share with team without requiring Dart SDK  
✅ **Convenience**: Simpler command syntax  
✅ **Reliability**: No dependency version conflicts  
✅ **Distribution**: Easy to deploy on multiple machines  

See [EXECUTABLE_GUIDE.md](EXECUTABLE_GUIDE.md) for more details.

## �📁 Output Structure

```
content_brief_gen/
├── results/
│   └── [timestamp]/                       # Timestamped session folder
│       ├── keyword_research_report.txt    # Comprehensive keyword analysis
│       ├── [title]_content_brief.txt      # Human-readable format
│       ├── [title]_content_brief.json     # Machine-readable data
│       ├── [title]_brief.docx             # Microsoft Word document
│       ├── [title]_article.md             # Full article (Markdown)
│       ├── [title]_article_wordpress.html # WordPress-ready HTML (copy-paste)
│       └── [title]_article_metadata.json  # Article generation metadata
├── lib/
│   ├── keyword_generator.dart             # Keyword research engine
│   ├── article_title_generator.dart       # AI title generation
│   ├── optimized_content_brief_generator.dart  # Unified brief generation
│   ├── article_generator.dart             # Claude article generation
│   ├── gemini_article_generator.dart      # Gemini article generation
│   └── word_document_generator.dart       # Document export
└── enhanced_seo_tool.dart                 # Main entry point
```

### **WordPress HTML Export**

When you generate a full article, you'll get a `*_wordpress.html` file that's ready to copy-paste directly into WordPress Block Editor:

**Features:**
- ✅ Clean HTML structure (no escaping issues)
- ✅ Block Editor compatible (`<b>`, `<i>` tags work perfectly)
- ✅ Proper heading hierarchy (`<h1>`, `<h2>`, `<h3>`)
- ✅ Lists formatted correctly (`<ul>`, `<ol>`, `<li>`)
- ✅ Paragraphs wrapped in `<p>` tags
- ✅ Bold text using `<b>` (not `<strong>`)
- ✅ Italic text using `<i>` (not `<em>`)

**How to Use:**
1. Generate article with the tool
2. Open `[title]_article_wordpress.html` file
3. Copy all content (Ctrl+A, Ctrl+C)
4. Paste into WordPress Block Editor
5. All formatting will be preserved perfectly!

**Example HTML Output:**
```html
<h1>Your SEO-Optimized Title</h1>
<p>Introduction paragraph with <b>bold text</b> and <i>italic text</i>.</p>
<h2>Main Section Heading</h2>
<p>Content paragraph...</p>
<ul>
<li>Bullet point one</li>
<li>Bullet point two</li>
</ul>
```

## 📄 Content Brief Structure

Each AI-generated content brief includes:

### **1. Primary Keyword Analysis**
- Target keyword with search intent analysis
- Keyword difficulty and competition insights

### **2. Topic Development**
- Comprehensive topic/theme for the article
- User intent matching and content angle recommendations

### **3. SEO Optimization**
- **Title**: Optimized H1 title (50-60 characters)
- **Meta Description**: Click-through optimized description (150-160 characters)

### **4. Content Structure**
- **Article Outline**: 6-8 main H2 sections
- **Keyword Integration**: Natural keyword placement suggestions
- **Related Topics**: Supporting subtopics and variations

### **5. AI-Generated Brand-Free Keywords**
- **Related Keywords**: 10-15 relevant keywords automatically generated by AI
- **Brand Filtering**: AI instructed to avoid brand names and focus on generic, informational terms
- **Context-Aware**: Keywords match user intent and topic relevance
- **Examples**: 
  - ✅ "cara merawat kulit", "tips skincare pemula", "urutan skincare yang benar"
  - ❌ NOT "wardah skincare", "somethinc serum", "shopee skincare"

## 💰 API Costs & Performance

### **Anthropic Claude Pricing**
- **Unified Generation**: Single API call per brief (optimized)
- **Typical Cost**: $0.0006-0.0009 per complete workflow (keyword research + title generation + brief)
- **Cost Breakdown**:
  - Input tokens: $0.25 per 1M tokens
  - Output tokens: $1.25 per 1M tokens
  - Average brief: ~500 input + ~600 output tokens

### **Performance Metrics**
- **Keyword Research**: 20-50 unique keywords per query (3-5 seconds)
- **AI Title Generation**: 5 titles in ~3-5 seconds
- **Content Brief Generation**: 3-6 seconds per brief with unified approach
- **Success Rate**: 99%+ with automatic retry and fallback mechanisms
- **Reliability**: Exponential backoff retry (3 attempts) + individual generation fallback

### **Cost Comparison**

**Old Approach (4 Separate API Calls)**:
- Topic generation: 1 call
- Title generation: 1 call  
- Meta description: 1 call
- Structure generation: 1 call
- **Total**: 4 API calls = $0.0013 per brief

**New Approach (Unified Generation)**:
- All components: 1 call
- AI title generation: 1 call
- **Total**: 2 API calls = $0.0009 per workflow
- **Savings**: 54% cost reduction on brief generation

### **Cost Optimization Features**
- ✅ Single unified API call for brief (vs 4 separate calls)
- ✅ Optimized prompt engineering (67% fewer tokens)
- ✅ Auto-retry with exponential backoff
- ✅ Rate limiting protection (500ms delays)
- ✅ Automatic fallback to prevent total failures

## 🔧 Advanced Configuration

### **Environment Variables**
```bash
# API Configuration
ANTHROPIC_API_KEY=sk-ant-your_key_here

# Debug Mode (optional)
ANTHROPIC_DEBUG=true
```

### **Customization Options**

#### **Keyword Research Sources**
- Enable/disable specific sources in the main function
- Adjust timeout and retry settings
- Customize user agent rotation

#### **Content Generation**
- Modify Claude model selection
- Adjust token limits for longer/shorter content
- Customize prompt templates for different content types

## 🚨 Troubleshooting

### **Dart SDK Not Found**
```bash
❌ 'dart' is not recognized as an internal or external command
```
**Solution:**
- Install Dart SDK following the instructions in the Setup section
- Make sure Dart is added to your system PATH
- Restart your terminal after installation
- Run `dart --version` to verify installation

### **Executable Permission Denied**
```bash
❌ ./seo-tool: Permission denied
```
**Solution:**
```bash
# Make executable
chmod +x seo-tool

# Or for shell script
chmod +x seo-tool.sh compile.sh
```

### **Executable Not Found After Global Install**
```bash
❌ seo-tool: command not found
```
**Solution:**
```bash
# Check if /usr/local/bin is in PATH
echo $PATH | grep "/usr/local/bin"

# If not found, add to PATH (macOS/Linux)
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify installation
which seo-tool
ls -la /usr/local/bin/seo-tool
```

### **Compilation Failed**
```bash
❌ Error: Could not find package 'http'
```
**Solution:**
```bash
# Install dependencies first
dart pub get

# Then compile
./compile.sh
```

### **Package Dependencies Issues**
```bash
❌ Error: Could not resolve the package 'anthropic_sdk_dart'
```
**Solution:**
```bash
# Re-fetch dependencies
dart pub get

# If that doesn't work, clean and reinstall
dart pub cache clean
dart pub get
```

### **API Key Issues**
```bash
❌ "Anthropic API key not found!"
```
**Solutions:**
- Ensure API key starts with `sk-ant-`
- Verify key is set in environment/config
- Check API key permissions at [Anthropic Console](https://console.anthropic.com)

### **SSL/Network Errors**
```bash
✅ DuckDuckGo Autocomplete: 0 results
```
**This is normal** - SSL errors are handled gracefully, tool continues with other sources.

### **Rate Limiting**
- Built-in delays prevent rate limiting (500ms minimum between requests)
- Automatic retry with exponential backoff (1s, 2s, 4s delays)
- Graceful degradation when limits hit
- Max 3 retry attempts before fallback

## 🎛️ Advanced Usage

### **AI Title Generation Features**

The tool includes intelligent AI title generation with brand filtering:

1. **Automatic Brand Detection** - AI avoids including brand names in generated titles
2. **SEO Optimization** - Titles are optimized for click-through rate and search visibility
3. **Indonesian Language** - Native Indonesian titles that sound natural
4. **User Intent Matching** - Titles match the search intent of the keyword
5. **Custom Input Option** - Always have the option to use your own title

**Example Title Patterns:**
- "Cara [Action]: Panduan Lengkap untuk Pemula"
- "[Number] Tips [Topic] yang Wajib Dicoba"
- "Panduan [Topic]: Dari Dasar hingga Mahir"
- "[Topic] Terbaik: Strategi dan Rekomendasi"

### **Brand-Free Keyword Generation**

Instead of passing scraped keywords (which may contain brands), the AI now generates clean, brand-free related keywords:

**Why AI Generation is Better:**
- ✅ Contextually relevant keywords based on the topic
- ✅ Zero brand contamination (AI understands brand context)
- ✅ No maintenance required (no brand lists to update)
- ✅ Works for any niche automatically
- ✅ Generates 10-15 high-quality keywords per brief

**AI Instruction:**
```
PENTING: JANGAN sertakan brand/merek tertentu di related_keywords
Fokus pada keywords umum dan informatif
```

### **Unified Generation Workflow**

The optimized approach generates all content components in a single API call:

```json
{
  "topic": "Optimized blog topic",
  "title": "SEO-friendly H1 title",
  "meta_description": "Compelling meta description",
  "article_structure": ["H2 heading 1", "H2 heading 2", ...],
  "related_keywords": ["keyword 1", "keyword 2", ...]
}
```

**Benefits:**
- 54% cost savings (1 call vs 4 calls)
- Faster generation (4-6 seconds total)
- Better consistency across components
- Automatic fallback if unified generation fails

### **Integration Examples**

#### **Content Marketing Workflow**
```bash
# 1. Research phase - discover keywords
dart run enhanced_seo_tool.dart "sustainable fashion trends 2025"

# 2. Content planning phase - generate brief with AI titles
dart run enhanced_seo_tool.dart "sustainable fashion trends 2025" --brief

# 3. Select your preferred title from AI-generated options
# 4. Review generated brief in results/[timestamp]/
```

#### **SEO Campaign Planning**
```bash
# Process multiple related keywords separately
dart run enhanced_seo_tool.dart "organic skincare routine" --brief
dart run enhanced_seo_tool.dart "natural beauty products" --brief
dart run enhanced_seo_tool.dart "clean beauty ingredients" --brief

# Each generates unique AI titles and brand-free keywords
```

#### **Client Project Workflow**
```bash
# 1. Initial keyword research
dart run enhanced_seo_tool.dart "bisnis online pemula"

# 2. Generate content brief with AI assistance
dart run enhanced_seo_tool.dart "bisnis online pemula" --brief

# 3. Present AI-generated title options to client
# 4. Deliver complete content brief with .docx export
```

## 🤝 Contributing

We welcome contributions! Please:

1. **Fork** the repository
2. **Create** a feature branch
3. **Make** your changes
4. **Test** thoroughly
5. **Submit** a pull request

### **Development Setup**
```bash
# Clone repository
git clone <repository-url>
cd content_brief_gen

# Install dependencies
dart pub get

# Run tests
dart test

# Run with development settings
dart run enhanced_seo_tool.dart "test" --brief
```

## 📈 Roadmap

- [x] **AI Title Generation** - Intelligent SEO-friendly title suggestions with brand filtering
- [x] **Brand-Free Keywords** - AI-generated related keywords without brand contamination
- [x] **Unified Generation** - Single API call optimization (54% cost savings)
- [x] **Interactive Workflow** - User selection of AI-generated titles
- [x] **Auto-Retry & Fallback** - 99% reliability with exponential backoff
- [x] **Dual AI Provider Support** - Anthropic Claude + Google Gemini (v3.1)
- [x] **Cost Optimization** - 97.9% savings with Gemini option
- [ ] **Additional AI Models** - Support for GPT-4, Claude Opus, etc.
- [ ] **Real-time Keyword Tracking** - Monitor keyword ranking changes
- [ ] **Competitor Analysis** - Automated competitor content analysis
- [ ] **Content Calendar** - Integrated content planning and scheduling
- [ ] **API Integration** - RESTful API for programmatic access
- [ ] **Web Interface** - Browser-based GUI for non-technical users
- [ ] **Multi-language Support** - Expand beyond Indonesian language

## 📜 License

This project is open source and available under the **MIT License**.

## 🆘 Support

For issues, questions, or feature requests:
- **Create an issue** in the repository
- **Check documentation** in the repository
- **Review troubleshooting** section above

---

## 📈 Performance & Cost Analysis

### **AI Provider Cost Comparison**

| Provider | Input Cost | Output Cost | Brief Cost | Speed | Quality |
|----------|-----------|-------------|------------|-------|---------|
| **Anthropic Claude** | $3.00/1M | $15.00/1M | $0.0105 | Fast | ⭐⭐⭐⭐⭐ |
| **Google Gemini** | $0.075/1M | $0.30/1M | $0.000225 | Ultra Fast | ⭐⭐⭐⭐ |
| **Savings** | 97.5% | 98% | **97.9%** | ⚡ | - |

### **Real-World Cost Examples**

| Usage | Claude Cost | Gemini Cost | Monthly Savings |
|-------|-------------|-------------|-----------------|
| 10 briefs | $0.105 | $0.00225 | $0.10 (97.9%) |
| 100 briefs | $1.05 | $0.0225 | $1.03 (97.9%) |
| 1000 briefs | $10.50 | $0.225 | $10.28 (97.9%) |

### **Before vs After Optimization (with Gemini)**

| Metric | Old Approach | Claude | Gemini | Improvement |
|--------|--------------|--------|--------|-------------|
| API Calls | 4 separate | 1 unified | 1 unified | 75% reduction |
| Cost per Brief | $0.0013 | $0.0105 | **$0.000225** | **82.7% cheaper** |
| Generation Time | ~15-20s | 3-6s | **1-2s** | **95% faster** |
| Success Rate | ~95% | 99%+ | 99%+ | Better reliability |
| Best Use Case | - | Premium | **High-volume** | More flexible |

## 🎯 Best Practices

### **Choosing the Right AI Provider**

**Use Google Gemini When:**
- ✅ Cost-effectiveness is important
- ✅ High-volume content generation (10+ briefs/day)
- ✅ Testing and experimentation
- ✅ Budget-conscious projects
- ✅ Fast turnaround needed (1-2s response)

**Use Anthropic Claude When:**
- ✅ Premium content quality required
- ✅ Complex reasoning and nuanced understanding needed
- ✅ Client-facing or critical content
- ✅ Budget allows for premium service
- ✅ Leveraging prompt caching for repeated operations

**Hybrid Approach (Best of Both):**
1. Use **Gemini** for initial drafts and bulk generation
2. Use **Claude** for high-priority or client-facing content
3. Test both providers to find your preference

### **Maximize Quality**
1. Review AI-generated titles carefully before selection
2. Use custom title input when you have specific requirements
3. Check generated meta descriptions for character count (150-160 optimal)
4. Verify article structure aligns with your content strategy
5. Review AI-generated related keywords for relevance
6. Compare outputs from both providers for important content

### **Workflow Optimization**
1. Start with keyword research to understand the topic landscape
2. Use the `--brief` flag for complete content planning workflow
3. Choose the right provider based on your needs (Gemini = cost, Claude = quality)
4. Select the most SEO-optimized title from AI suggestions
5. Export results in multiple formats (.txt, .json, .docx) for different team members
6. Keep all results organized in timestamped folders

### **Cost Efficiency**
1. Default to Gemini for most content generation (97.9% savings)
2. Use unified generation (default) for best cost-performance ratio
3. Rely on AI-generated keywords instead of manual research
4. Leverage automatic retry and fallback for reliability
5. Monitor performance metrics to track API usage
6. Reserve Claude for premium content only

## 🔄 Recent Updates

### **v3.1 - Dual AI Provider Support (October 2025)**
- ✅ **Google Gemini Integration** - 97.9% cheaper alternative to Claude
- ✅ **Provider Selection** - Choose between Anthropic or Gemini with `--provider` flag
- ✅ **Flexible API Configuration** - Support for multiple API key sources
- ✅ **Cost Optimization** - Gemini: $0.000225 per brief vs Claude: $0.0105
- ✅ **Speed Improvement** - Gemini delivers results in 1-2 seconds
- ✅ **Maintained Quality** - Both providers deliver excellent SEO content
- ✅ **Backward Compatible** - Defaults to Anthropic if no provider specified

### **v3.0 - AI Title Generation & Brand-Free Keywords (October 2025)**
- ✅ AI-powered title generation with 5-10 SEO-optimized suggestions
- ✅ Interactive title selection workflow with custom input option
- ✅ Brand-free keyword generation using AI (no manual filtering needed)
- ✅ Explicit AI instruction to avoid brand names in keywords and titles
- ✅ Enhanced user experience with clear workflow steps
- ✅ Maintained unified generation for cost efficiency

### **v2.0 - Optimized Unified Generation**
- ✅ Unified generation in 1 API call (54% cost savings)
- ✅ Optimized prompts (67% token reduction)
- ✅ Auto-retry with exponential backoff
- ✅ Automatic fallback to individual generation
- ✅ Rate limiting protection (500ms delays)
- ✅ Real-time performance metrics tracking
- ✅ Native Indonesian language support

---

**🎉 Ready to optimize your SEO content creation with dual AI providers, 97.9% cost savings, and flexible provider selection!**

**📚 Additional Documentation:**
- [AI_PROVIDER_COMPARISON.md](AI_PROVIDER_COMPARISON.md) - Detailed provider comparison
