# Contributing to Enhanced SEO Tool

Thank you for your interest in contributing! This document provides guidelines for contributing to the Enhanced SEO Tool project.

## 🤝 How to Contribute

### 1. **Reporting Issues**
- Use the GitHub issue tracker
- Provide detailed descriptions
- Include steps to reproduce
- Specify your environment (OS, Dart version)

### 2. **Suggesting Features**
- Check existing issues first
- Provide clear use cases
- Explain the expected behavior
- Consider implementation complexity

### 3. **Code Contributions**

#### **Prerequisites**
- Dart SDK 3.0.0 or higher
- Basic understanding of HTTP APIs
- Familiarity with async/await patterns

#### **Development Setup**
```bash
# 1. Fork the repository
git clone https://github.com/your-username/content_brief_gen.git
cd content_brief_gen

# 2. Install dependencies
dart pub get

# 3. Set up API key for testing
export ANTHROPIC_API_KEY="sk-ant-your-test-key"

# 4. Run tests
dart run enhanced_seo_tool.dart "test keyword"
```

#### **Development Workflow**
1. **Create a branch** from main
2. **Make your changes** with clear commits
3. **Test thoroughly** with different keywords
4. **Update documentation** if needed
5. **Submit a pull request**

## 📝 Code Style Guidelines

### **Dart Style**
- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` for code formatting
- Use meaningful variable and function names
- Add comments for complex logic

### **Project Structure**
```
bin/                    # Core keyword research functionality
lib/                    # Reusable modules and generators
├── content_brief_generator.dart
├── word_document_generator.dart
enhanced_seo_tool.dart  # Main application entry point
```

### **Naming Conventions**
- **Functions**: camelCase with descriptive verbs
- **Classes**: PascalCase with clear purpose
- **Files**: snake_case matching functionality
- **Constants**: SCREAMING_SNAKE_CASE

## 🧪 Testing Guidelines

### **Manual Testing**
Always test these scenarios:
```bash
# Basic functionality
dart run enhanced_seo_tool.dart "test keyword"

# Content brief generation
dart run enhanced_seo_tool.dart "test keyword" --brief

# Batch processing
dart run enhanced_seo_tool.dart "test keyword" --brief --batch

# Error handling (no API key)
unset ANTHROPIC_API_KEY
dart run enhanced_seo_tool.dart "test keyword" --brief
```

### **Testing Different Keywords**
- Short keywords (1-2 words)
- Long keywords (3+ words)
- Non-English keywords
- Special characters and symbols

### **Network Error Testing**
- Disconnect internet during execution
- Use invalid API keys
- Test timeout scenarios

## 🐛 Bug Reports

### **Good Bug Report Includes:**
1. **Clear title** describing the issue
2. **Steps to reproduce** the problem
3. **Expected behavior** vs actual behavior
4. **Environment details** (OS, Dart version)
5. **Error messages** or logs if available
6. **Screenshots** if relevant

### **Example Bug Report**
```
Title: DuckDuckGo SSL error on Windows 10

Description:
When running keyword research, getting SSL handshake errors for DuckDuckGo.

Steps to reproduce:
1. Run: dart run enhanced_seo_tool.dart "test"
2. Wait for DuckDuckGo autocomplete phase

Expected: DuckDuckGo results or graceful handling
Actual: SSL handshake exception crashes tool

Environment:
- OS: Windows 10
- Dart: 3.0.0
- Error: HandshakeException: CERTIFICATE_VERIFY_FAILED
```

## ✨ Feature Requests

### **Good Feature Request Includes:**
1. **Clear problem statement** - What problem does this solve?
2. **Proposed solution** - How should it work?
3. **Use cases** - When would this be useful?
4. **Implementation notes** - Any technical considerations

### **Current Development Priorities**
1. **Additional AI Models** - GPT-4, Gemini support
2. **Real-time Monitoring** - Keyword ranking tracking
3. **Competitor Analysis** - Automated content analysis
4. **Web Interface** - Browser-based GUI
5. **API Endpoints** - RESTful API access

## 📚 Documentation

### **Documentation Updates**
- Update README.md for new features
- Add examples to usage guides
- Update API documentation
- Include changelog entries

### **Code Documentation**
```dart
/// Fetches autocomplete suggestions from Google
/// 
/// [keyword] The search term to get suggestions for
/// Returns list of suggestion strings, empty list on error
Future<List<String>> fetchAutocomplete(String keyword) async {
  // Implementation...
}
```

## 🔄 Pull Request Process

### **Before Submitting**
- [ ] Code follows Dart style guidelines
- [ ] All tests pass
- [ ] Documentation is updated
- [ ] Commit messages are clear
- [ ] No sensitive data in commits

### **Pull Request Template**
```markdown
## Description
Brief description of changes made.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement

## Testing
- [ ] Tested manually with different keywords
- [ ] Error handling verified
- [ ] No regressions introduced

## Related Issues
Fixes #123
```

### **Review Process**
1. **Automated checks** - Code formatting and basic tests
2. **Manual review** - Logic and design review
3. **Testing** - Functionality verification
4. **Merge** - After approval from maintainers

## 🏷️ Release Process

### **Version Numbering**
- **Major** (x.0.0) - Breaking changes or major features
- **Minor** (0.x.0) - New features, backwards compatible
- **Patch** (0.0.x) - Bug fixes and small improvements

### **Release Checklist**
- [ ] All tests pass
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version number bumped
- [ ] Git tag created
- [ ] Release notes written

## 💬 Communication

### **Channels**
- **Issues** - Bug reports and feature requests
- **Pull Requests** - Code review and discussion
- **Discussions** - General questions and ideas

### **Response Times**
- **Issues** - Usually within 2-3 days
- **Pull Requests** - Within 1 week
- **Security Issues** - Within 24 hours

## 🙏 Recognition

Contributors will be:
- Listed in the project's CONTRIBUTORS.md
- Mentioned in release notes
- Credited for significant contributions

Thank you for contributing to the Enhanced SEO Tool! 🚀