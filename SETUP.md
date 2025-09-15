# ITEL App Setup Guide

## Required Files NOT in GitHub (Backup these!)

### Firebase Configuration
- `android/app/google-services.json` - Download from Firebase Console
- `ios/Runner/GoogleService-Info.plist` - Download from Firebase Console

### Development Environment
- `android/local.properties` - Created automatically by Android Studio

## New Machine Setup

### 1. Install Development Tools
- [ ] Flutter SDK: https://flutter.dev/docs/get-started/install
- [ ] Android Studio: https://developer.android.com/studio  
- [ ] VS Code with Flutter extension (optional)
- [ ] Xcode (Mac only, for iOS development)

### 2. Clone & Setup Repository
```bash
git clone <your-github-repo-url>
cd itel-app-final
flutter pub get
```

### 3. Configure Firebase
1. Go to Firebase Console: https://console.firebase.google.com
2. Download `google-services.json` → place in `android/app/`
3. Download `GoogleService-Info.plist` → place in `ios/Runner/`

### 4. Configure APIs
- [ ] Xendit API keys in `lib/config/xendit_config.dart`
- [ ] Check Firebase project settings
- [ ] Verify Moodle integration URL: https://lms.itel.com.sg

### 5. Test Setup
```bash
flutter doctor
flutter run
```

## Important Notes
- Never commit Firebase config files to GitHub
- Keep API keys secure
- Update production keys before going live
- Test on both Android and iOS devices

## Firebase Project Details
- Project: [Your Firebase Project Name]
- Authentication: Email/Password, Google, Anonymous enabled
- Firestore: Users collection, course subcollections
- Hosting: [If applicable]