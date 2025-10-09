#!/bin/bash

# Wrapper script to run the Dart SEO tool
# This version requires Dart SDK to be installed

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run the Dart application with all arguments passed through
dart run "$SCRIPT_DIR/enhanced_seo_tool.dart" "$@"
