# Glowly AI Integration Guide

## Overview

Glowly now includes a complete AI integration that connects to Claude API, OpenAI, or OpenRouter. The AI provides personalized beauty advice based on user profiles and product collections.

**Features:**
- ✅ Real-time streaming responses
- ✅ Context-aware (user profile + products)
- ✅ Multiple AI provider support (Claude, OpenAI, OpenRouter)
- ✅ Error handling with fallback to mock responses
- ✅ Comprehensive system prompts for beauty domain
- ✅ Secure API key configuration

---

## Setup Instructions

### Step 1: Get Your API Key

Choose one of the following providers:

#### Option A: Claude API (Anthropic) - **RECOMMENDED**
1. Go to https://console.anthropic.com/
2. Sign up or log in
3. Navigate to "API Keys"
4. Click "Create Key"
5. Copy your API key (starts with `sk-ant-`)

**Pricing:** Pay-as-you-go, ~$3 per million input tokens
**Model:** `claude-3-5-sonnet-20241022` (latest)

#### Option B: OpenAI API
1. Go to https://platform.openai.com/api-keys
2. Sign up or log in
3. Click "Create new secret key"
4. Copy your API key (starts with `sk-`)

**Pricing:** Pay-as-you-go, ~$10 per million input tokens
**Model:** `gpt-4-turbo-preview`

#### Option C: OpenRouter API (Multiple Models)
1. Go to https://openrouter.ai/keys
2. Sign up or log in
3. Click "Create Key"
4. Copy your API key

**Pricing:** Varies by model, generally cheapest option
**Models:** Access to 100+ models including Claude, GPT-4, Llama, etc.

### Step 2: Configure API Key

1. Open `Glowly/Services/Config/APIConfig.swift`
2. Replace the placeholder with your actual API key:

```swift
// For Claude (Anthropic)
static let claudeAPIKey = "sk-ant-YOUR-ACTUAL-KEY-HERE"

// OR for OpenAI
static let openAIAPIKey = "sk-YOUR-ACTUAL-KEY-HERE"

// OR for OpenRouter
static let openRouterAPIKey = "YOUR-OPENROUTER-KEY-HERE"
```

3. Set the active provider:

```swift
static let activeProvider: AIProvider = .claude  // or .openAI or .openRouter
```

### Step 3: Add to .gitignore (IMPORTANT!)

To avoid accidentally committing your API keys:

```bash
# In your .gitignore file, add:
**/APIConfig.swift
```

### Step 4: Build and Test

1. Build the project (⌘B)
2. Run on simulator or device
3. Navigate to the AI Helper tab
4. Send a test message: "Create a morning routine for me"
5. The AI should respond with personalized advice!

---

## Architecture

### Files Created

```
Glowly/Services/
├── Config/
│   └── APIConfig.swift          # API keys and configuration
└── AI/
    ├── AIService.swift          # Main AI service implementation
    └── AISystemPrompts.swift    # System prompts for beauty domain
```

### Updated Files

```
Glowly/Views/AI/
└── AIHelperView.swift           # Updated to use real AI service
```

### How It Works

```
User Message
    ↓
AIHelperView.sendMessage()
    ↓
Build system prompt with:
    - User profile (skin type, concerns, goals)
    - Product collection
    - Conversation history
    ↓
AIService.sendMessageStream()
    ↓
Choose provider (Claude/OpenAI/OpenRouter)
    ↓
HTTP Request to AI API
    ↓
Stream response chunks
    ↓
Display in chat UI
```

### System Prompt

The AI receives comprehensive context:

```swift
- User Profile:
  - Skin type (dry, oily, combination, etc.)
  - Skin conditions (acne, redness, etc.)
  - Beauty goals (anti-aging, hydration, etc.)
  - Allergies and sensitivities
  - Experience level
  - Makeup frequency

- Product Collection:
  - All active products by category
  - Expiration warnings
  - Brand and product names

- Guidelines:
  - Personalization based on profile
  - Reference products from cosmetic bag
  - Warn about allergens
  - Explain ingredients
  - Provide step-by-step routines
```

---

## API Provider Comparison

| Feature | Claude (Anthropic) | OpenAI | OpenRouter |
|---------|-------------------|---------|------------|
| **Price** | Medium ($3/M tokens) | High ($10/M tokens) | Low (varies) |
| **Quality** | Excellent | Excellent | Varies by model |
| **Speed** | Fast | Fast | Varies |
| **Streaming** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Context** | 200K tokens | 128K tokens | Varies |
| **Best For** | Production | High quality | Development/Testing |

**Recommendation:** Use **Claude** for production, **OpenRouter** for development.

---

## Advanced Configuration

### Change AI Model

In `APIConfig.swift`:

```swift
// Claude models
static let claudeModel = "claude-3-5-sonnet-20241022"  // Latest (recommended)
// static let claudeModel = "claude-3-opus-20240229"   // Most capable
// static let claudeModel = "claude-3-haiku-20240307"  // Fastest, cheapest

// OpenAI models
static let openAIModel = "gpt-4-turbo-preview"  // Latest GPT-4
// static let openAIModel = "gpt-4"             // Standard GPT-4
// static let openAIModel = "gpt-3.5-turbo"     // Cheaper, faster

// OpenRouter (use any model)
// "anthropic/claude-3.5-sonnet"
// "openai/gpt-4-turbo-preview"
// "meta-llama/llama-3-70b-instruct"
```

### Adjust AI Parameters

```swift
static let maxTokens = 2000      // Max response length
static let temperature = 0.7     // Creativity (0.0-1.0)
static let timeoutInterval: TimeInterval = 30  // Request timeout
```

**Temperature Guide:**
- `0.0-0.3`: More focused, deterministic
- `0.4-0.7`: Balanced (recommended)
- `0.8-1.0`: More creative, varied

### Customize System Prompts

Edit `AISystemPrompts.swift`:

```swift
static func getSystemPrompt(userProfile: UserProfile, products: [Product]) -> String {
    return """
    You are an AI beauty expert...

    // Add your custom instructions here
    - Focus on specific concerns
    - Use specific brand knowledge
    - Add regional preferences
    """
}
```

### Add Quick Action Prompts

```swift
static let myCustomPrompt = """
    Analyze my skincare routine and suggest improvements.
    """
```

---

## Error Handling

### Built-in Error Types

```swift
AIServiceError {
    .invalidAPIKey        // API key missing or invalid
    .networkError         // Network connectivity issue
    .invalidResponse      // Malformed API response
    .apiError(message)    // API returned an error
    .rateLimitExceeded    // Too many requests
    .timeout              // Request took too long
}
```

### Fallback Behavior

If the AI API fails:
1. Error message shown to user
2. Automatic fallback to mock responses
3. Haptic feedback (warning/error)
4. User can retry

---

## Cost Estimation

### Example Usage (per user per month)

**Assumptions:**
- 10 AI conversations per user/month
- 5 messages per conversation
- 200 tokens input + 500 tokens output per message

**Calculations:**

```
Total tokens/month = 10 * 5 * (200 + 500) = 35,000 tokens

Claude (Anthropic):
Input:  10K tokens * $3/1M = $0.03
Output: 25K tokens * $15/1M = $0.375
Total: ~$0.41/user/month

OpenAI (GPT-4):
Input:  10K tokens * $10/1M = $0.10
Output: 25K tokens * $30/1M = $0.75
Total: ~$0.85/user/month

OpenRouter (Claude 3.5):
Similar to Anthropic, often slightly cheaper
```

**For 1000 active users:**
- Claude: ~$410/month
- OpenAI: ~$850/month
- OpenRouter: ~$300-400/month

---

## Production Deployment

### Security Best Practices

⚠️ **NEVER hardcode API keys in production!**

**Better approaches:**

1. **Backend Proxy** (Recommended)
   ```
   iOS App → Your Backend → AI API
   ```
   - Store API key on server
   - Implement rate limiting
   - Add authentication
   - Monitor usage

2. **Environment Variables**
   ```bash
   # In Xcode build settings
   CLAUDE_API_KEY = $(CLAUDE_API_KEY)
   ```

3. **CI/CD Secrets**
   - Store in GitHub Secrets
   - Inject during build
   - Never commit to repo

### Rate Limiting

Add to `AIService.swift`:

```swift
private var requestCount = 0
private var lastRequestTime = Date()

func checkRateLimit() throws {
    let timeInterval = Date().timeIntervalSince(lastRequestTime)

    if timeInterval < 1.0 && requestCount > 5 {
        throw AIServiceError.rateLimitExceeded
    }

    if timeInterval >= 60.0 {
        requestCount = 0
        lastRequestTime = Date()
    }

    requestCount += 1
}
```

### Usage Monitoring

Track costs:

```swift
struct UsageMetrics {
    var totalRequests: Int
    var totalTokens: Int
    var estimatedCost: Double
}

func logUsage(tokens: Int) {
    // Send to your analytics service
    // Update user quota
    // Alert if approaching limit
}
```

---

## Testing

### Test with Mock Responses

Set this in `APIConfig.swift` for testing:

```swift
static let useMockResponses = true  // Add this flag
```

### Test Different Scenarios

```swift
// Test cases in AIHelperView
func testMorningRoutine()
func testProductAnalysis()
func testAllergyWarning()
func testExpirationReminder()
```

### Test Error Handling

```swift
// Simulate errors
throw AIServiceError.networkError(NSError(...))
throw AIServiceError.rateLimitExceeded
throw AIServiceError.timeout
```

---

## LangChain / LangGraph Integration

**Do You Need It?**

For this mobile app: **NO**

**Why not:**
- LangChain is primarily for Python
- Adds unnecessary complexity for simple chat
- Direct API calls are more performant
- Easier to debug and maintain

**When to use LangChain/LangGraph:**
- Complex multi-agent workflows
- Need for tool/function calling
- Document retrieval (RAG)
- Chain-of-thought reasoning
- Running on backend server

**Alternative for iOS:**
If you need advanced features, consider:
1. Build backend with LangChain (Python)
2. Expose REST API
3. Call from iOS app

---

## Troubleshooting

### Issue: "Invalid API key" error

**Solution:**
1. Check that API key is correct
2. Ensure no spaces or quotes
3. Verify provider is set correctly
4. Check API key has billing enabled

### Issue: Streaming not working

**Solution:**
1. Check network connectivity
2. Verify streaming is supported by model
3. Try non-streaming mode first
4. Check for firewall/proxy issues

### Issue: Slow responses

**Solution:**
1. Reduce `maxTokens` (try 1000)
2. Use faster model (Claude Haiku, GPT-3.5)
3. Implement caching for common queries
4. Consider shorter system prompts

### Issue: Responses not personalized

**Solution:**
1. Verify user profile is complete
2. Check products are being included
3. Review system prompt in logs
4. Ensure profile passed to AI service

### Issue: High costs

**Solution:**
1. Implement caching for similar queries
2. Use cheaper models for simple questions
3. Reduce conversation history sent
4. Add rate limiting per user
5. Consider OpenRouter for cost savings

---

## Next Steps

### Enhancements

1. **Conversation History Persistence**
   ```swift
   // Save to UserDefaults or Core Data
   func saveConversation()
   func loadConversation()
   ```

2. **Image Analysis**
   ```swift
   // Send product photos to Claude Vision
   func analyzeProductImage(image: UIImage)
   ```

3. **Voice Input**
   ```swift
   // Use Speech Recognition
   import Speech
   func startVoiceRecognition()
   ```

4. **Suggested Responses**
   ```swift
   // Quick reply buttons
   var suggestedReplies: [String] = [
       "Tell me more",
       "Show products",
       "Create routine"
   ]
   ```

5. **Multi-language**
   ```swift
   // Auto-detect language
   func detectLanguage(text: String) -> Language
   ```

---

## Support & Resources

### Documentation
- Claude API: https://docs.anthropic.com/
- OpenAI API: https://platform.openai.com/docs
- OpenRouter: https://openrouter.ai/docs

### Community
- Anthropic Discord: https://discord.gg/anthropic
- OpenAI Forum: https://community.openai.com/

### Pricing
- Claude Pricing: https://www.anthropic.com/pricing
- OpenAI Pricing: https://openai.com/pricing
- OpenRouter Models: https://openrouter.ai/models

---

## License & Compliance

**Usage Guidelines:**
- Follow provider's terms of service
- Don't use for medical diagnosis
- Respect user privacy
- Comply with GDPR/CCPA
- Monitor for inappropriate content

**Attribution:**
- OpenAI requires attribution
- Claude recommends disclosure
- Display "Powered by Claude AI" or similar

---

**Setup Complete!** 🎉

You now have a fully functional AI beauty assistant integrated into Glowly. Test it thoroughly and adjust the system prompts to match your brand voice!
