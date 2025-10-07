# Message Batches Implementation

## Overview
The SEO Content Brief Generator now supports Anthropic's Message Batches API for cost-efficient bulk content generation with **50% cost savings** compared to individual API calls.

## Features

### Batch Processing Benefits
- **50% Cost Reduction**: Message Batches are half the price of individual requests
- **Higher Throughput**: Process multiple keywords simultaneously
- **Efficient Resource Usage**: Batch API optimizes server resources
- **Automatic Fallback**: Falls back to individual processing if batch fails

### Supported Operations
- ✅ Batch topic generation
- ✅ Batch title creation
- ✅ Batch meta description writing
- ✅ Batch article structure outlining
- ✅ Batch result saving and organization

## Usage

### Basic Commands

```bash
# Keyword research only
dart run enhanced_seo_tool.dart "your keyword"

# Individual content brief generation
dart run enhanced_seo_tool.dart "your keyword" --brief

# Batch content brief generation (50% cost savings)
dart run enhanced_seo_tool.dart "your keyword" --brief --batch
```

### API Key Setup

For Anthropic Claude API, you need a valid API key that starts with `sk-ant-`:

```bash
# Environment variable
$env:ANTHROPIC_API_KEY="sk-ant-your_anthropic_api_key_here"

# .env file
ANTHROPIC_API_KEY=sk-ant-your_anthropic_api_key_here

# config.json file
{
  "anthropic_api_key": "sk-ant-your_anthropic_api_key_here"
}
```

## Batch Processing Workflow

1. **Batch Creation**: Creates requests for all keywords (4 requests per keyword)
2. **Batch Submission**: Submits batch to Anthropic's Message Batches API
3. **Polling**: Monitors batch processing status every 10 seconds
4. **Result Processing**: Retrieves and processes completed batch results
5. **File Generation**: Creates individual text, JSON, and Word files
6. **Batch Summary**: Generates a comprehensive batch summary file

## Output Structure

```
results/
├── keyword_research_reports/     # Individual keyword research
├── content_briefs/              # Individual content briefs
│   ├── keyword1_content_brief.txt
│   ├── keyword1_content_brief.json
│   └── keyword1_brief.docx
└── content_briefs/batch/        # Batch processing results
    ├── batch_summary_2025-10-07.json
    └── [individual files...]
```

## Implementation Details

### Batch Request Structure
Each keyword generates 4 batch requests:
- Topic generation request
- Title generation request
- Meta description request
- Article structure request

### Error Handling
- **Authentication Errors**: Falls back to individual processing
- **Rate Limiting**: Automatic retry with exponential backoff
- **API Failures**: Graceful degradation with error reporting
- **Partial Failures**: Continues processing remaining keywords

### Performance Metrics
- **Cost Savings**: Up to 50% reduction in API costs
- **Processing Time**: Batch processing for 5 keywords typically takes 30-60 seconds
- **Throughput**: Can handle 20+ keywords in a single batch request

## API Key Notes

⚠️ **Important**: Make sure you're using a valid Anthropic API key (starts with `sk-ant-`), not an OpenAI key (starts with `sk-`).

Get your Anthropic API key from: https://console.anthropic.com/settings/keys

## Example Output

When using batch processing, you'll see:

```
🚀 Using batch processing for 5 keywords (50% cost savings)...
📦 Batch created with ID: batch_abc123...
⏳ Waiting for batch processing...
⏳ Batch status: in_progress
✅ Batch processing completed!
📊 Processing batch results for 5 keywords...
💾 Saving 5 content briefs from batch processing...
✅ Batch summary saved: results/content_briefs/batch/batch_summary_2025-10-07.json
📊 Successfully saved 5 content briefs
```

## Troubleshooting

### Common Issues
1. **Authentication Error**: Verify your Anthropic API key format
2. **Batch Timeout**: Large batches may take longer to process
3. **Model Availability**: Ensure the specified Claude model is available

### Debug Mode
Add debug logging by setting the environment variable:
```bash
$env:ANTHROPIC_DEBUG="true"
```