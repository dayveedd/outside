# OneSignal Push Notification Permission Flow

When integrating OneSignal in Flutter / iOS applications:
1. **Avoid Circular Deadlocks**: Do not gate native permission prompts (`OneSignal.Notifications.requestPermission(true)`) exclusively on receiving a server-assigned subscription ID. On fresh installs or iOS simulators, subscription IDs are not minted until permission and APNs tokens are granted.
2. **Contextual Permission Prompts**: Trigger permission requests at high-intent moments: immediately post-signup, upon first arriving at the home feed, or via explicit "Enable Daily Reminders" CTAs.
3. **Dedicated In-App Controls**: Always provide a clear toggle or status indicator in the user Settings screen so users can check their permission status and trigger system permission prompts at will.
