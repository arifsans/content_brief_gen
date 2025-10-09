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
    echo "You can now run it with:"
    echo "  ./seo-tool \"your keyword\""
    echo "  ./seo-tool \"your keyword\" --brief"
    echo ""
    echo "To make it globally accessible, move it to your PATH:"
    echo "  sudo mv seo-tool /usr/local/bin/"
else
    echo ""
    echo "❌ Compilation failed!"
    exit 1
fi
