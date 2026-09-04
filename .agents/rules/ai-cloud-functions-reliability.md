# AI Cloud Functions Reliability & Observability

When building scheduled backend functions that call third-party AI APIs (such as OpenRouter):
1. **Dual Trigger Architecture**: Provide both a scheduled cron job (`onSchedule`) and an HTTP-triggerable endpoint (`onRequest`) to enable immediate manual testing, debugging, and verification via browser or curl.
2. **Comprehensive Telemetry**: Never catch and silently swallow API errors in production functions. Log detailed response data (`error.response?.data || error.message`) and rethrow or return HTTP 500 status codes so failures are transparent.
3. **Robust Sanitization**: Strip markdown code fences (` ```json `) from LLM outputs and validate required schema keys before committing documents to Firestore.
