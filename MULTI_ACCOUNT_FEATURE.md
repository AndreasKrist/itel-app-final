# Multi-Account Switcher Feature

## Overview

This feature allows users to quickly switch between multiple accounts they've logged into, similar to Instagram's account switcher. Users can see a list of their previously logged-in accounts and switch between them with a single tap.

## Features

- **Account List**: Shows all accounts that have been logged into the app
- **Quick Switching**: Tap an account to switch to it
- **Account Info**: Displays account name, email, profile picture (for Google accounts), account type (private/corporate), and authentication method
- **Account Management**: Remove accounts from the saved list
- **Persistent Storage**: Accounts are saved locally and persist across app restarts
- **Firebase Integration**: Seamlessly works with existing Firebase Authentication
- **State Management**: Uses Provider for efficient state management

## Architecture

### Components

1. **SavedAccount Model** (`lib/models/saved_account.dart`)
   - Stores minimal account information for display
   - Includes UID, email, display name, photo URL, account type, auth method, and last used timestamp
   - Serializable to/from JSON for local storage

2. **UserProvider** (`lib/providers/user_provider.dart`)
   - Manages current user state across the app
   - Replaces the static `User.currentUser` singleton pattern
   - Handles list of saved accounts
   - Notifies listeners when user or account list changes

3. **AccountManagerService** (`lib/services/account_manager_service.dart`)
   - Handles persistence of saved accounts in SharedPreferences
   - CRUD operations for saved accounts
   - Limits to 10 saved accounts maximum
   - Sorts accounts by last used (most recent first)

4. **AccountSwitcher Widget** (`lib/widgets/account_switcher.dart`)
   - UI component displaying the list of accounts
   - Handles account switching logic
   - Shows current account indicator
   - Provides account removal functionality

5. **Updated AuthService** (`lib/services/auth_service.dart`)
   - Automatically saves accounts after successful login
   - Provides `switchToAccount()` method
   - Provides `removeAccount()` method
   - Works with both Google and email/password authentication

## How It Works

### Account Saving Flow

1. User logs in (via Google or email/password)
2. After successful authentication, `_saveAccountAfterLogin()` is called
3. Account details are extracted from Firebase User
4. Account is saved to SharedPreferences via AccountManagerService
5. UserProvider is updated with the new account list

### Account Switching Flow

1. User taps on a saved account in the AccountSwitcher
2. App signs out current user
3. For Google accounts: Attempts silent sign-in
4. For email accounts: Returns null (user needs to enter password)
5. After successful switch, user data is loaded from Firestore
6. UserProvider is updated with new user
7. Last used timestamp is updated for the account
8. UI refreshes to show new user's data

### Account Display

- Accounts are shown only when there are 2 or more saved accounts
- Current account is highlighted with a "Current" badge
- Accounts are sorted by last used (most recent at top)
- Each account shows:
  - Profile picture (Google accounts) or initials
  - Display name
  - Email address
  - Auth method icon (Google or email)
  - Account type (Private or Corporate)

## Data Storage

### SharedPreferences Structure

```json
{
  "saved_accounts_list": "[{\"uid\":\"...\",\"email\":\"...\",\"displayName\":\"...\",\"photoUrl\":\"...\",\"accountType\":\"private\",\"authMethod\":\"google\",\"lastUsed\":\"2025-11-28T...\"}, ...]"
}
```

### Firestore Integration

- User profile data remains in Firestore (`users/{uid}`)
- Switching accounts loads data from the selected user's Firestore document
- No changes to existing Firestore structure

## Security Considerations

### What's NOT Stored

- **Passwords**: Never stored locally (handled by Firebase)
- **Auth Tokens**: Managed by Firebase SDK internally
- **Sensitive User Data**: Only basic profile info (name, email) is cached

### What IS Stored

- User ID (Firebase UID)
- Email address
- Display name
- Profile photo URL (from Google)
- Account type (private/corporate)
- Authentication method (google/email)
- Last used timestamp

### Security Measures

- Firebase handles all authentication tokens
- Full sign-out required when switching accounts
- Email accounts require password re-entry
- Google accounts use Firebase's silent sign-in (if session still valid)
- No sensitive data in local storage

## Limitations

### Firebase Constraints

1. **Single Session Per Device**: Firebase only allows one authenticated user at a time
2. **Re-Authentication Required**: Must sign out current user before signing in as another
3. **Email Accounts**: Require password re-entry (can't auto-login)
4. **Google Accounts**: Use silent sign-in if Google session is still active

### Implementation Constraints

1. **Maximum 10 Saved Accounts**: Configurable in `AccountManagerService`
2. **No Offline Switching**: Requires internet connection to load user data from Firestore
3. **No Multi-Device Sync**: Saved accounts list is device-specific

## Database Impact

### No Breaking Changes

- ✅ Firestore structure unchanged
- ✅ Firebase Authentication unchanged
- ✅ Existing user data intact
- ✅ Backward compatible

### What Changed

- Added local storage for saved accounts list
- Added Provider for state management
- Updated auth flow to save accounts
- Static `User.currentUser` still works (for backward compatibility)

## Usage

### For Users

1. **Login with First Account**: Use Google or email/password login
2. **Switch Accounts**: Go to Profile tab → See "Switch Account" section (appears after 2+ logins)
3. **Add More Accounts**: Sign out → Login with different account
4. **Quick Switch**: Tap any account in the list to switch
5. **Remove Account**: Tap the X icon next to an account

### For Developers

```dart
// Access current user via Provider
final userProvider = Provider.of<UserProvider>(context);
final currentUser = userProvider.currentUser;

// Or use the traditional way (still works)
final user = User.currentUser;

// Switch to an account programmatically
final authService = AuthService();
await authService.switchToAccount(savedAccount);

// Remove an account from saved list
await authService.removeAccount(uid);
```

## Testing Checklist

- [ ] Login with Google account → Account saved
- [ ] Login with email/password account → Account saved
- [ ] Login with second account → Both accounts appear in switcher
- [ ] Switch to Google account → Seamless switch (if session active)
- [ ] Switch to email account → Prompted for password
- [ ] Remove account from list → Account removed
- [ ] App restart → Saved accounts persist
- [ ] Profile data loads correctly after switch
- [ ] Favorites and enrollments load correctly after switch
- [ ] Sign out → Switcher updates correctly
- [ ] Corporate account shows "Corporate" label
- [ ] Private account shows "Private" label

## Future Enhancements

1. **Biometric Authentication**: Add fingerprint/face unlock for quick switching
2. **Account Sync**: Sync saved accounts across devices
3. **Session Management**: Keep multiple sessions active in background
4. **Push Notifications**: Per-account notification management
5. **Quick Actions**: Long-press account for quick actions (view profile, sign out, etc.)
6. **Account Search**: Search saved accounts by name/email
7. **Account Groups**: Group accounts by type (personal, work, etc.)

## Troubleshooting

### Account Switcher Not Showing

- Make sure you have logged in with at least 2 different accounts
- Check that Provider is properly initialized in main.dart

### Can't Switch to Email Account

- Email accounts require password for security
- You'll be redirected to login screen with email pre-filled

### Lost Saved Accounts After Reinstall

- Saved accounts are stored locally
- Reinstalling the app clears local data
- Just login again to re-save accounts

### Account Shows Wrong Data

- Tap the account to switch and reload data
- Force reload by signing out and back in

## Code Locations

- **Models**: `lib/models/saved_account.dart`
- **Providers**: `lib/providers/user_provider.dart`
- **Services**:
  - `lib/services/account_manager_service.dart`
  - `lib/services/auth_service.dart` (updated)
- **Widgets**: `lib/widgets/account_switcher.dart`
- **Screens**: `lib/screens/profile_screen.dart` (updated)
- **Main**: `lib/main.dart` (updated)

## Dependencies

```yaml
dependencies:
  provider: ^6.1.1  # State management
  shared_preferences: ^2.2.0  # Local storage (already in project)
  firebase_auth: ^4.6.3  # Firebase authentication (already in project)
  cloud_firestore: ^4.8.2  # Firestore database (already in project)
```

## Summary

This feature provides a seamless multi-account experience without breaking any existing functionality. It uses industry-standard patterns (Provider for state management) and respects Firebase's constraints. The implementation is secure, efficient, and user-friendly.
