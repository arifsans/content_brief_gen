#!/bin/bash

# Script to compile the Dart application to a native executable

echo "🔨 Compiling enhanced_seo_tool.dart to native executable..."
echo ""

# Compile to native executable
dart compile exe enhanced_seo_tool.dart -o seo-tool

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Compilation successful!"
    echo ""
    echo "📦 Executable created: ./seo-tool"
    echo ""
    echo "🚀 You can now run it with:"
    echo "  ./seo-tool"
    echo ""
    echo "💡 The tool will guide you through:"
    echo "   1. Enter your target keyword"
    echo "   2. Choose workflow (Full or Research only)"
    echo "   3. Select AI provider (Claude or Gemini)"
    echo ""
    echo "⚡ To make it globally accessible, move it to your PATH:"
    echo "  sudo mv seo-tool /usr/local/bin/"
    echo ""
    echo "📚 See QUICK_REFERENCE.md for usage guide"
else
    echo ""
    echo "❌ Compilation failed!"
    exit 1
fi
