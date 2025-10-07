# 🚀 Quick Start Guide

Get up and running with the Enhanced SEO Tool in under 5 minutes!

## ⚡ Installation (2 minutes)

### 1. **Prerequisites**
- Dart SDK 3.0.0+ ([Download here](https://dart.dev/get-dart))
- Anthropic API key ([Get here](https://console.anthropic.com/settings/keys))

### 2. **Setup**
```bash
# Install dependencies
dart pub get

# Set API key (choose one method)
$env:ANTHROPIC_API_KEY="sk-ant-your_key_here"  # Windows PowerShell
export ANTHROPIC_API_KEY="sk-ant-your_key_here"  # Linux/Mac
echo "ANTHROPIC_API_KEY=sk-ant-your_key_here" > .env  # .env file
```

## 🎯 First Run (1 minute)

### **Test Keyword Research**
```bash
# Basic keyword research (no API key needed)
dart run enhanced_seo_tool.dart "digital marketing"
```

**Expected Output:**
```
🚀 Enhanced SEO Research & Content Brief Generator
✅ Google Autocomplete: 15 results
✅ Bing Autocomplete: 12 results
✅ Found 25 unique keywords
```

### **Test AI Content Briefs**
```bash
# Full functionality with AI (requires API key)
dart run enhanced_seo_tool.dart "coffee brewing" --brief --batch
```

**Expected Output:**
```
📦 Batch created with ID: batch_abc123...
✅ Batch processing completed!
📊 Successfully saved 5 content briefs
```

## 📁 Check Your Results

After running, check these folders:
- `results/` - Keyword research reports
- `content_briefs/` - AI-generated content briefs

## 🆘 Troubleshooting

### **"Anthropic API key not found"**
```bash
# Verify your API key is set
echo $ANTHROPIC_API_KEY  # Linux/Mac
echo $env:ANTHROPIC_API_KEY  # Windows PowerShell
```

### **SSL/Network Errors**
These are handled gracefully - the tool continues with available sources.

## 📖 Next Steps

1. **Read Full Documentation**: [README.md](README.md)
2. **Learn Batch Processing**: [BATCH_PROCESSING.md](BATCH_PROCESSING.md)
3. **Explore Examples**: Try different keywords and options

## 💡 Pro Tips

- **Use batch processing** (`--batch`) for multiple keywords to save 50% on API costs
- **Check results folder** regularly - files are timestamped for easy tracking
- **Start with keyword research only** to understand your topic before generating briefs

---

**🎉 You're ready to start creating professional SEO content briefs!**

For detailed documentation, see [README.md](README.md)