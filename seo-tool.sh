#!/bin/bash

# Wrapper script to run the Dart SEO tool
# This version requires Dart SDK to be installed
#
# Usage (v3.2+): Simply run without arguments
#   ./seo-tool.sh
#
# The tool will interactively prompt you for:
#   1. Target keyword
#   2. Workflow choice (Full or Research only)
#   3. AI provider (Claude or Gemini)

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run the Dart application with all arguments passed through
dart run "$SCRIPT_DIR/enhanced_seo_tool.dart" "$@"
