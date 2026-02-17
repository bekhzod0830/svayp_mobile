# Onboarding State Management

## Overview
The app now remembers whether a user has completed onboarding. After completing the registration flow once, users will go directly to the Main Screen on subsequent app launches.

## How It Works

### First Launch
```
Splash Screen → Check storage (isOnboarded = false)
    ↓
Welcome Screen → Phone Auth → ... → Style Quiz → Completion Screen
    ↓
Save: isOnboarded = true
    ↓
Navigate to Main Screen
```

### Subsequent Launches
```
Splash Screen → Check storage (isOnboarded = true)
    ↓
Main Screen (directly)
```

## Implementation Files

### 1. **LocalStorageHelper** (`lib/core/utils/local_storage_helper.dart`)
- Singleton class managing SharedPreferences
- Methods:
  - `isOnboarded()` - Check if onboarding completed
  - `setOnboarded(bool)` - Save onboarding status
  - `clearOnboarding()` - Reset for testing
  - `clearAll()` - Complete app data reset

### 2. **Splash Screen** (`lib/features/onboarding/presentation/screens/splash_screen.dart`)
- Checks onboarding status on app launch
- Routes to Welcome (new user) or Main (returning user)

### 3. **Completion Screen** (`lib/features/onboarding/presentation/screens/onboarding_completion_screen.dart`)
- Saves `isOnboarded = true` when user completes onboarding
- Uses `pushNamedAndRemoveUntil` to clear navigation stack

## Testing During Development

### Method 1: Clear App Data (Recommended)
For iOS Simulator:
```bash
# Uninstall and reinstall
flutter clean
flutter run
```

For Android:
```bash
# Go to Settings → Apps → Swipe → Storage → Clear Data
# OR
adb shell pm clear uz.swipe.app  # Replace with your package name
```

### Method 2: Add Debug Reset Button (Temporary)
Add this code temporarily to any screen during development:

```dart
// TEMPORARY DEBUG BUTTON - Remove before production!
FloatingActionButton(
  onPressed: () async {
    final storage = await LocalStorageHelper.getInstance();
    await storage.clearOnboarding();
    print('Onboarding cleared! Restart app.');
  },
  child: Icon(Icons.refresh),
)
```

### Method 3: Programmatic Reset
In your code (for testing):

```dart
import 'package:swipe/core/utils/local_storage_helper.dart';

// Reset onboarding
final storage = await LocalStorageHelper.getInstance();
await storage.clearOnboarding();

// Or clear all app data
await storage.clearAll();
```

## Storage Keys Used

Defined in `lib/core/constants/app_constants.dart`:

```dart
static const String isOnboardedKey = 'is_onboarded';  // Main onboarding flag
static const String userTokenKey = 'user_token';       // Auth token
static const String userIdKey = 'user_id';            // User ID
static const String userProfileKey = 'user_profile';   // User data JSON
static const String themeKey = 'theme_mode';          // Theme preference
```

## User Data Management

### Logout Implementation (Future)
When implementing logout, clear relevant data:

```dart
Future<void> logout() async {
  final storage = await LocalStorageHelper.getInstance();
  
  // Clear auth data
  await storage.clearAuthData();
  
  // Keep onboarding completed (user doesn't need to onboard again)
  // await storage.clearOnboarding(); // Don't call this
  
  // Navigate to login
  Navigator.pushNamedAndRemoveUntil(context, '/phone-auth', (route) => false);
}
```

### Account Deletion
When user deletes account, clear everything:

```dart
Future<void> deleteAccount() async {
  final storage = await LocalStorageHelper.getInstance();
  await storage.clearAll(); // Clear EVERYTHING
  
  // Navigate to welcome
  Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
}
```

## Benefits

✅ **Better UX**: Users don't repeat onboarding  
✅ **Persistent**: Works across app restarts  
✅ **Fast**: Direct navigation to main content  
✅ **Flexible**: Easy to reset for testing  
✅ **Clean**: Proper separation of concerns  

## Production Notes

- Remove any debug reset buttons before release
- Consider adding analytics to track onboarding completion rates
- May want to add "Redo Onboarding" option in Settings later
- Storage is encrypted on iOS/Android by default (secure)

## Future Enhancements

- [ ] Add onboarding version tracking (for future onboarding updates)
- [ ] Track which specific steps were completed
- [ ] Allow partial onboarding (save progress if user exits mid-flow)
- [ ] Add "Skip for now" with reminders to complete later
- [ ] Analytics: track drop-off rates at each onboarding step
