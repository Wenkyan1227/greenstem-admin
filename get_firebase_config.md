# Quick Firebase Configuration Guide

## Get Configuration from Existing "greenstem-mobile" Project

### Step 1: Go to Firebase Console
1. Visit: https://console.firebase.google.com/
2. Select your "greenstem-mobile" project

### Step 2: Add Admin App to Project

#### For Android:
1. Click the Android icon (</>) 
2. Enter package name: `com.example.greenstem_admin`
3. Enter app nickname: "GreenStem Admin"
4. Click "Register app"
5. Download `google-services.json`
6. Replace `android/app/google-services.json` with the downloaded file

#### For iOS:
1. Click the iOS icon
2. Enter bundle ID: `com.example.greenstemAdmin`
3. Enter app nickname: "GreenStem Admin"
4. Click "Register app"
5. Download `GoogleService-Info.plist`
6. Replace `ios/Runner/GoogleService-Info.plist` with the downloaded file

#### For Web:
1. Click the Web icon (</>)
2. Enter app nickname: "GreenStem Admin Web"
3. Click "Register app"
4. Copy the configuration values

### Step 3: Update firebase_options.dart

Replace the placeholder values in `lib/firebase_options.dart` with actual values from your Firebase project:

```dart
// Example of what to replace:
apiKey: 'YOUR_ANDROID_API_KEY', // Replace with actual API key
appId: 'YOUR_ANDROID_APP_ID',   // Replace with actual App ID
messagingSenderId: 'YOUR_SENDER_ID', // Replace with actual Sender ID
```

### Step 4: Test Configuration

```bash
flutter pub get
flutter run
```

## Alternative: Use Firebase CLI

If you have Node.js installed:

```bash
npm install -g firebase-tools
firebase login
dart pub global run flutterfire_cli:flutterfire configure --project=greenstem-mobile
```

This will automatically generate the correct configuration for all platforms. 