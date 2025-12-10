# Complete Prompt for iOS Multi-Account Switcher Implementation

Copy and paste this entire prompt to Claude Code for your iOS project:

---

**PROMPT START:**

I want to implement a multi-account switcher feature for my iOS app, exactly like Instagram's account switcher. Users should be able to:
1. Login with multiple accounts (email/password and Google Sign-In)
2. See a dropdown arrow next to their name in the profile header
3. Tap their name to see a bottom sheet with all saved accounts
4. Switch between accounts quickly
5. Remove accounts from the saved list

## Current App Structure:

My iOS app uses:
- **Firebase Authentication** (email/password + Google Sign-In)
- **Firestore** for user data storage
- User profile data structure similar to this:
```json
{
  "name": "User Name",
  "email": "user@email.com",
  "phone": "...",
  "company": "...",
  "accountType": "private" or "corporate",
  "tier": "standard/tier1/tier2/tier3",
  "favoriteCoursesIds": [...],
  "enrolledCourses": [...],
  ...other fields
}
```

## IMPORTANT Implementation Requirements:

### 1. State Management
- Use **SwiftUI's @StateObject and @ObservedObject** pattern (similar to Flutter's Provider)
- Replace any singleton User pattern with proper state management
- Create a UserViewModel/UserState class

### 2. Account Storage
- Store saved accounts in **UserDefaults** (similar to SharedPreferences in Flutter)
- Save minimal account info: UID, email, displayName, photoURL, accountType, authMethod, lastUsed
- Limit to 10 saved accounts maximum

### 3. Security
- **NEVER store passwords** locally
- Only store Firebase UID and basic profile info
- Let Firebase handle all auth tokens
- Email accounts require password re-entry when switching
- Google accounts can use silent sign-in if session is active

### 4. UI Requirements - Instagram Style

#### Profile Header (where user name is displayed):
- Add a dropdown chevron icon next to the user's name
- Only show chevron if user has 2+ saved accounts
- Make the name + chevron tappable
- On tap, show a bottom sheet with all accounts

#### Bottom Sheet/Modal:
- Title: "Switch Account" with account count (e.g., "4 accounts")
- List all saved accounts with:
  - Circle avatar (with initials or profile photo)
  - Display name (font size: 15pt)
  - Email (font size: 13pt)
  - Account type badge (Corporate/Private, font size: 11pt)
  - Auth method icon (Google or Email icon)
  - Current account shows "Current" badge in blue
  - Other accounts show an X button to remove
- Rounded corners at top
- Dismissible by swiping down or tapping outside

#### Password Dialog (for email accounts):
- Title: "Enter Password"
- Subtitle: "Sign in as [Name]" and email below
- Password text field with lock icon
- Cancel button (gray)
- Sign In button (blue background, WHITE text)
- Make dialog width 85% of screen width
- Auto-focus on password field

### 5. Implementation Steps:

**Step 1: Create Data Models**
```swift
// SavedAccount.swift
struct SavedAccount: Codable, Identifiable {
    let id: String  // Firebase UID
    let email: String
    let displayName: String
    let photoURL: String?
    let accountType: String  // "private" or "corporate"
    let authMethod: String   // "google" or "email"
    let lastUsed: Date

    // Add toJSON and fromJSON methods for UserDefaults storage
}
```

**Step 2: Create State Management**
```swift
// UserViewModel.swift
class UserViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var savedAccounts: [SavedAccount] = []
    @Published var isLoading: Bool = false

    func setUser(_ user: User?)
    func setSavedAccounts(_ accounts: [SavedAccount])
    func addSavedAccount(_ account: SavedAccount)
    func removeSavedAccount(uid: String)
    func clearUser()
}
```

**Step 3: Create Account Manager Service**
```swift
// AccountManagerService.swift
class AccountManagerService {
    private let savedAccountsKey = "saved_accounts_list"

    func loadSavedAccounts() -> [SavedAccount]
    func saveSavedAccounts(_ accounts: [SavedAccount])
    func addOrUpdateAccount(_ account: SavedAccount)
    func removeAccount(uid: String)
    func updateLastUsed(uid: String)

    // Store/retrieve from UserDefaults as JSON
}
```

**Step 4: Update Authentication Service**
```swift
// AuthService.swift
// Add these methods to your existing auth service:

func saveAccountAfterLogin(_ firebaseUser: User, authMethod: String) {
    // Get account type from Firestore
    // Create SavedAccount object
    // Save to AccountManagerService
}

func switchToAccount(_ account: SavedAccount) async throws -> User? {
    // Sign out current user
    // If Google account: try silent sign-in
    // If email account: return nil (need password)
}

func removeAccount(uid: String) {
    // Remove from AccountManagerService
}

// Update all sign-in methods (signInWithGoogle, signInWithEmail, register)
// to call saveAccountAfterLogin() after successful login
```

**Step 5: Create Account Switcher View**
```swift
// AccountSwitcherView.swift
struct AccountSwitcherView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Binding var isPresented: Bool
    let onAccountSwitched: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Switch Account")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Text("\(userViewModel.savedAccounts.count) accounts")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding()

            Divider()

            // Account List
            ForEach(userViewModel.savedAccounts) { account in
                AccountListItemView(
                    account: account,
                    isCurrentUser: account.id == userViewModel.currentUser?.id,
                    onTap: { switchToAccount(account) },
                    onRemove: { removeAccount(account) }
                )
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func switchToAccount(_ account: SavedAccount) {
        // Show password dialog if email account
        // Otherwise switch directly
    }

    private func removeAccount(_ account: SavedAccount) {
        // Show confirmation dialog
        // Remove from saved accounts
    }
}

struct AccountListItemView: View {
    let account: SavedAccount
    let isCurrentUser: Bool
    let onTap: () -> Void
    let onRemove: () -> Void

    var body: some View {
        Button(action: isCurrentUser ? {} : onTap) {
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color.blue)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(account.displayName.prefix(1)))
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                    )

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.displayName)
                        .font(.system(size: 15))
                        .fontWeight(isCurrentUser ? .bold : .regular)

                    Text(account.email)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)

                    HStack(spacing: 4) {
                        Image(systemName: account.authMethod == "google" ? "g.circle" : "envelope")
                            .font(.system(size: 12))
                        Text(account.accountType == "corporate" ? "Corporate" : "Private")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.gray)
                }

                Spacer()

                // Trailing
                if isCurrentUser {
                    Text("Current")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(12)
                } else {
                    Button(action: onRemove) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
        .background(isCurrentUser ? Color.blue.opacity(0.05) : Color.white)
    }
}
```

**Step 6: Create Password Dialog**
```swift
// PasswordDialogView.swift
struct PasswordDialogView: View {
    let account: SavedAccount
    @Binding var isPresented: Bool
    @State private var password: String = ""
    let onSubmit: (String) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Password")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text("Sign in as \(account.displayName)")
                Text(account.email)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(.gray)

                Spacer()

                Button("Sign In") {
                    onSubmit(password)
                    isPresented = false
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color(red: 0, green: 86/255, blue: 172/255))
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: UIScreen.main.bounds.width * 0.85)
        .background(Color.white)
        .cornerRadius(12)
    }
}
```

**Step 7: Update Profile Header**
```swift
// In your ProfileView.swift or ProfileHeaderView:

// Add to your profile header where the user name is displayed:
HStack {
    Text(userViewModel.currentUser?.name ?? "User")
        .font(.system(size: 24, weight: .bold))
        .foregroundColor(.white)

    if userViewModel.savedAccounts.count > 1 {
        Image(systemName: "chevron.down")
            .foregroundColor(.white)
            .font(.system(size: 20))
    }
}
.onTapGesture {
    if userViewModel.savedAccounts.count > 1 {
        showAccountSwitcher = true
    }
}
.sheet(isPresented: $showAccountSwitcher) {
    AccountSwitcherView(
        isPresented: $showAccountSwitcher,
        onAccountSwitched: {
            // Reload user data
            Task {
                await loadUserData()
            }
        }
    )
    .environmentObject(userViewModel)
}
```

**Step 8: Update App Entry Point**
```swift
// In your App.swift or main entry point:
@main
struct YourApp: App {
    @StateObject private var userViewModel = UserViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userViewModel)
        }
    }
}
```

**Step 9: Load Saved Accounts on App Start**
```swift
// In your main view's onAppear or init:
.onAppear {
    let accountManager = AccountManagerService()
    let savedAccounts = accountManager.loadSavedAccounts()
    userViewModel.setSavedAccounts(savedAccounts)

    // If user is authenticated, load their data
    if let currentUser = Auth.auth().currentUser {
        Task {
            await loadUserData()
            userViewModel.setUser(loadedUser)
        }
    }
}
```

## Key Implementation Notes:

1. **Google Sign-In**: Use Firebase's Google Sign-In SDK for iOS
2. **Bottom Sheet**: Use `.sheet()` or `.presentationDetents()` for iOS 16+
3. **UserDefaults**: Store SavedAccounts as JSON using Codable
4. **Async/Await**: Use Swift's async/await for Firebase operations
5. **Error Handling**: Show alerts for failed sign-ins or incorrect passwords

## Exact Behavior:

- **Email Account Switching**: Show password dialog → Sign in with email/password
- **Google Account Switching**: Try silent sign-in → Show Google picker if needed
- **Account Removal**: Show confirmation alert → Remove from UserDefaults
- **Current Account**: Highlighted with blue badge, not tappable
- **Empty State**: Don't show dropdown arrow if only 1 account

## Testing Checklist:

- [ ] Login with Google → Account saved
- [ ] Login with email → Account saved
- [ ] Login with 2nd account → Dropdown arrow appears
- [ ] Tap name → Bottom sheet appears
- [ ] Tap email account → Password dialog appears
- [ ] Enter password → Account switches successfully
- [ ] Tap Google account → Switches (or shows Google picker)
- [ ] Remove account → Confirmation shown → Account removed
- [ ] Restart app → Saved accounts persist
- [ ] Sign out → Dropdown arrow disappears (if only 1 account left)

## Files to Create:

1. `Models/SavedAccount.swift`
2. `ViewModels/UserViewModel.swift`
3. `Services/AccountManagerService.swift`
4. `Views/AccountSwitcherView.swift`
5. `Views/PasswordDialogView.swift`

## Files to Modify:

1. `Services/AuthService.swift` - Add account saving logic
2. `Views/ProfileView.swift` - Add dropdown to header
3. `YourApp.swift` - Add @StateObject userViewModel

Please implement this feature exactly as described, making sure the UI matches the Instagram-style design with proper font sizes, colors, and animations. Use SwiftUI best practices and ensure all security requirements are met.

**PROMPT END**

---

## Additional Tips for iOS Implementation:

If you encounter issues, refer to these Flutter-to-iOS equivalents:

| Flutter | iOS (SwiftUI) |
|---------|---------------|
| Provider | @StateObject / @EnvironmentObject |
| ChangeNotifier | ObservableObject |
| SharedPreferences | UserDefaults |
| showModalBottomSheet | .sheet() or .presentationDetents() |
| AlertDialog | Alert() |
| Consumer<T> | @EnvironmentObject |
| Navigator.pop() | dismiss() / isPresented = false |
| TextField | TextField / SecureField |

Good luck with your iOS implementation! 🚀
