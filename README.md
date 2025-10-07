# 🚀 Enhanced SEO Tool - Advanced Keyword Research & AI Content Brief Generator

A comprehensive, professional-grade SEO tool that combines multi-source keyword research with AI-powered content brief generation using Anthropic Claude API. Features intelligent batch processing for cost efficiency and scalable content creation.

## ✨ Features

### 🔍 **Multi-Source Keyword Research**
- **Google Autocomplete** - Real-time search suggestions with user intent analysis
- **Google Related Searches** - Bottom page suggestions and semantic keywords
- **People Also Ask** - Question-based keywords for FAQ optimization
- **Bing Autocomplete** - Microsoft search engine diversity and alternative perspectives
- **DuckDuckGo Autocomplete** - Privacy-focused search engine data with SSL error handling

### 🤖 **AI-Powered Content Brief Generation**
- **Anthropic Claude Integration** - Advanced AI using Claude 3 Haiku for natural, SEO-optimized content
- **Batch Processing** - 50% cost savings with Message Batches API for bulk content generation
- **SEO-Optimized Titles** - Character-limited, keyword-focused H1 titles (50-60 chars)
- **Meta Descriptions** - Compelling, click-through optimized descriptions (150-160 chars)
- **Article Structure** - Detailed H2/H3 outline with 6-8 main sections
- **Topic Analysis** - Comprehensive topic recommendations with user intent focus
- **Related Keywords Integration** - Seamless integration of researched keywords into content structure

### 📊 **Export & Organization**
- **Multiple Formats** - TXT, JSON, and Microsoft Word documents
- **Organized Structure** - Automatic folder organization and file naming
- **Batch Summaries** - Comprehensive batch processing reports
- **Professional Reports** - Detailed keyword research with source attribution

## 🛠️ Setup & Installation

### 1. **Install Dependencies**
```bash
# Clone or download the project
cd content_brief_gen

# Install Dart dependencies
dart pub get
```

### 2. **Set up Anthropic Claude API Key**

Get your API key from [Anthropic Console](https://console.anthropic.com/settings/keys)

**Choose one setup method:**

**Option A: Environment Variable (Recommended)**
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
# Create .env file in project root
echo "ANTHROPIC_API_KEY=sk-ant-your_anthropic_api_key_here" > .env
```

**Option C: config.json File**
```json
{
  "anthropic_api_key": "sk-ant-your_anthropic_api_key_here"
}
```

### 3. **Verify Installation**
```bash
# Test keyword research (no API key needed)
dart run enhanced_seo_tool.dart "test keyword"

# Test full functionality (requires API key)
dart run enhanced_seo_tool.dart "test keyword" --brief
```

## 🎯 Usage Guide

### **Basic Commands**

#### **Keyword Research Only**
```bash
dart run enhanced_seo_tool.dart "your keyword here"
```

#### **Individual Content Brief Generation**
```bash
dart run enhanced_seo_tool.dart "your keyword here" --brief
```

#### **Batch Content Brief Generation (50% Cost Savings)**
```bash
dart run enhanced_seo_tool.dart "your keyword here" --brief --batch
```

### **Practical Examples**

```bash
# Indonesian keyword research
dart run enhanced_seo_tool.dart "cara membuat kopi"

# English SEO analysis with individual content briefs
dart run enhanced_seo_tool.dart "digital marketing strategies" --brief

# Batch processing for cost efficiency (recommended for multiple keywords)
dart run enhanced_seo_tool.dart "organic gardening tips" --brief --batch

# Complex multi-word keywords
dart run enhanced_seo_tool.dart "resep masakan sehat untuk diabetes" --brief --batch
```

### **Command Options**

| Option | Description | Use Case |
|--------|-------------|----------|
| (none) | Keyword research only | Quick keyword discovery |
| `--brief` | Individual content brief generation | Standard content creation |
| `--brief --batch` | Batch processing with 50% cost savings | Bulk content planning |

## 📁 Output Structure

```
content_brief_gen/
├── results/
│   ├── keyword_research_reports/          # Timestamped keyword research
│   │   ├── keyword_07-Oktober-2025_14-30.txt
│   │   └── keyword_analysis_summary.json
│   └── content_briefs/                    # Individual content briefs
│       ├── keyword_content_brief.txt      # Human-readable format
│       ├── keyword_content_brief.json     # Machine-readable data
│       ├── keyword_brief.docx             # Microsoft Word document
│       └── batch/                         # Batch processing results
│           ├── batch_summary_2025-10-07.json
│           └── individual_brief_files...
├── bin/
│   └── content_brief_gen.dart             # Core keyword research engine
├── lib/
│   ├── content_brief_generator.dart       # AI content generation
│   └── word_document_generator.dart       # Document export functionality
└── enhanced_seo_tool.dart                 # Main application entry point
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

### **5. Keyword Integration**
- **Related Keywords**: Top 10 supporting keywords from research
- **Long-tail Variations**: Question-based and intent-specific keywords
- **Semantic Keywords**: Context and relevance enhancers

## 💰 API Costs & Performance

### **Anthropic Claude Pricing**
- **Individual Processing**: Standard API rates
- **Batch Processing**: 50% cost reduction through Message Batches API
- **Typical Cost**: $0.01-0.05 per content brief (varies by keyword complexity)

### **Performance Metrics**
- **Keyword Research**: 20-50 unique keywords per query (3-5 seconds)
- **Individual Content Brief**: 30-60 seconds per brief
- **Batch Processing**: 5 briefs in 60-90 seconds with 50% cost savings
- **Success Rate**: 95%+ with automatic fallback handling

### **Cost Comparison**
```
Individual Processing:  5 briefs = $0.25-0.50
Batch Processing:      5 briefs = $0.12-0.25 (50% savings)
```

## 🔧 Advanced Configuration

### **Environment Variables**
```bash
# API Configuration
ANTHROPIC_API_KEY=sk-ant-your_key_here

# Debug Mode
ANTHROPIC_DEBUG=true

# Custom Settings
MAX_KEYWORDS=20
TIMEOUT_SECONDS=30
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

### **Batch Processing Errors**
```bash
❌ Error in batch processing: authentication_error
💡 Falling back to individual processing...
```
**Automatic fallback** - Tool continues with individual processing when batch fails.

### **Rate Limiting**
- Built-in delays prevent rate limiting
- Automatic retry with exponential backoff
- Graceful degradation when limits hit

## 🎛️ Advanced Usage

### **Batch Processing Workflow**
1. **Keyword Research** → Discovers 20-50 keywords
2. **Batch Creation** → Groups top 5 keywords for processing
3. **API Submission** → Sends batch request to Anthropic
4. **Status Monitoring** → Polls batch status every 10 seconds
5. **Result Processing** → Downloads and processes completed briefs
6. **File Generation** → Creates TXT, JSON, and Word documents

### **Integration Examples**

#### **Content Marketing Workflow**
```bash
# 1. Research phase
dart run enhanced_seo_tool.dart "sustainable fashion trends 2025"

# 2. Content planning phase
dart run enhanced_seo_tool.dart "sustainable fashion trends 2025" --brief --batch

# 3. Review generated briefs in results/content_briefs/
```

#### **SEO Campaign Planning**
```bash
# Multiple related keywords
dart run enhanced_seo_tool.dart "organic skincare routine" --brief --batch
dart run enhanced_seo_tool.dart "natural beauty products" --brief --batch
dart run enhanced_seo_tool.dart "clean beauty ingredients" --brief --batch
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

- [ ] **Additional AI Models** - Support for GPT-4, Gemini, etc.
- [ ] **Real-time Keyword Tracking** - Monitor keyword ranking changes
- [ ] **Competitor Analysis** - Automated competitor content analysis
- [ ] **Content Calendar** - Integrated content planning and scheduling
- [ ] **API Integration** - RESTful API for programmatic access
- [ ] **Web Interface** - Browser-based GUI for non-technical users

## 📜 License

This project is open source and available under the **MIT License**.

## 🆘 Support

For issues, questions, or feature requests:
- **Create an issue** in the repository
- **Check documentation** in the `/docs` folder
- **Review troubleshooting** section above

---

**Made with ❤️ for SEO professionals and content creators**