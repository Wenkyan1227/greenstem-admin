# Firebase Setup Guide for GreenStem Admin

## Prerequisites
- Flutter SDK installed
- Firebase account
- Android Studio / Xcode (for platform-specific setup)
- Existing Firebase project: `greenstem-mobile`

## Step 1: Use Existing Firebase Project

You already have a Firebase project called "greenstem-mobile". We'll configure your admin app to use the same Firebase database as your mobile app.

**Benefits of using the same Firebase project:**
- Shared data between mobile and admin apps
- Consistent user authentication
- Unified analytics and monitoring
- Single billing account

## Step 2: Install FlutterFire CLI (Recommended)

```bash
dart pub global activate flutterfire_cli
```

## Step 3: Configure Firebase with FlutterFire CLI

```bash
flutterfire configure --project=greenstem-mobile
```

This will:
- Add your Flutter app to your existing "greenstem-mobile" Firebase project
- Generate `firebase_options.dart` with correct configuration
- Set up all platforms (Android, iOS, Web)
- Connect to the same database as your mobile app

## Step 4: Manual Configuration (Alternative)

If you prefer manual setup:

### Android Setup
1. In Firebase Console, select your "greenstem-mobile" project
2. Click Android icon (</>) to add a new Android app
3. Enter package name: `com.example.greenstem_admin`
4. Enter app nickname: "GreenStem Admin"
5. Download `google-services.json`
6. Place it in `android/app/google-services.json`

### iOS Setup
1. In Firebase Console, select your "greenstem-mobile" project
2. Click iOS icon to add a new iOS app
3. Enter bundle ID: `com.example.greenstemAdmin`
4. Enter app nickname: "GreenStem Admin"
5. Download `GoogleService-Info.plist`
6. Place it in `ios/Runner/GoogleService-Info.plist`

### Web Setup
1. In Firebase Console, select your "greenstem-mobile" project
2. Click Web icon (</>) to add a new Web app
3. Enter app nickname: "GreenStem Admin Web"
4. Copy the configuration object

## Step 5: Update Dependencies

Run the following command to get all dependencies:

```bash
flutter pub get
```

## Step 6: Test Firebase Connection

Run the app to test Firebase initialization:

```bash
flutter run
```

## Step 7: Verify Firebase Services

Since you're using an existing Firebase project, verify that these services are enabled:

### Firestore Database
1. Go to Firestore Database
2. If not created, click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location

### Authentication
1. Go to Authentication
2. If not set up, click "Get started"
3. Enable sign-in methods (Email/Password, Google, etc.)

### Storage
1. Go to Storage
2. If not set up, click "Get started"
3. Choose "Start in test mode" (for development)
4. Select a location

## Step 8: Security Rules

Since you're using an existing Firebase project, check your current security rules:

### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to all users under any document
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

### Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true;
    }
  }
}
```

**Note:** These are test rules. For production, implement proper authentication and authorization. Since you're sharing the database with your mobile app, make sure the rules work for both applications.

## Step 9: Environment Variables (Optional)

For production, consider using environment variables:

1. Create `.env` file:
```
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
```

2. Add to `.gitignore`:
```
.env
```

## Troubleshooting

### Common Issues

1. **Firebase initialization error**
   - Check if configuration files are in correct locations
   - Verify package names match Firebase console

2. **Android build error**
   - Clean and rebuild: `flutter clean && flutter pub get`
   - Check `google-services.json` is in `android/app/`

3. **iOS build error**
   - Check `GoogleService-Info.plist` is in `ios/Runner/`
   - Verify bundle ID matches Firebase console

4. **Web build error**
   - Check Firebase configuration in `firebase_options.dart`
   - Verify web app is added to Firebase project

### Useful Commands

```bash
# Clean and rebuild
flutter clean
flutter pub get

# Check Firebase configuration
flutterfire configure

# Run with verbose logging
flutter run --verbose
```

## Next Steps

After Firebase is set up:

1. Implement authentication in your app
2. Set up Firestore collections for your data models
3. Configure proper security rules
4. Test all Firebase services
5. Deploy to production with proper security rules

## Support

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/) 