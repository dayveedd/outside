# Resilient Daily Content & Empty States

When developing micro-learning or daily-drop mobile apps (such as Outside):
1. **Never throw uncaught exceptions** when daily content documents are missing from the database.
2. **First-Class Empty States**: Treat `DailyLessonEmpty` as a first-class state rather than an error state.
3. **Editorial Welcome Instance**: Display an inviting, brand-aligned welcome card introducing the app's core mission, pillars, and the exact drop cadence (00:00 UTC).
4. **Actionable Onboarding CTAs**: Offer direct actions on the empty state (such as enabling push notifications or browsing the historical archive) so new users are immediately engaged.
