# eKora — Egypt's Competitive Gaming & Tournament Platform

A production-ready Flutter + Firebase mobile app for organizing and competing in gaming tournaments across Egypt.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter 3.x (Dart 3) |
| State Management | Riverpod 2.x |
| Navigation | GoRouter 13.x |
| Backend | Firebase (Auth, Firestore, Storage, Functions, FCM, Crashlytics) |
| Architecture | Clean Architecture — feature-based |
| Payments | Vodafone Cash / Fawry / Credit Card (Cloud Function verified) |
| Fonts | Cairo (Arabic + Latin) |

---

## Project Structure

```
lib/
├── main.dart                    # App entry — Firebase init, Hive, Crashlytics
├── app.dart                     # MaterialApp.router + ThemeMode provider
├── firebase_options.dart        # ⚠️ Replace with your FlutterFire config
│
├── core/
│   ├── constants/               # AppConstants, AppStrings
│   ├── errors/                  # Failures, Exceptions
│   ├── network/                 # NetworkInfo (connectivity check)
│   ├── router/                  # GoRouter + route names
│   ├── services/                # NotificationService, StorageService
│   ├── theme/                   # AppTheme (dark/light), AppColors
│   ├── utils/                   # Logger, Validators, Extensions
│   └── widgets/                 # AppButton, LoadingWidget, ErrorWidget, EmptyState
│
└── features/
    ├── auth/                    # Login, Register, Forgot Password, Social Auth
    ├── home/                    # Shell (bottom nav) + home dashboard
    ├── tournaments/             # List, Detail, Join
    ├── rankings/                # Global leaderboard + podium
    ├── profile/                 # User profile + edit + avatar upload
    ├── payments/                # Vodafone Cash / Fawry / Card flow
    └── admin/                   # Dashboard, Create Tournament, Users, Payments

functions/
├── index.js                     # Cloud Functions (payments, rankings, notifications)
└── package.json

firestore.rules                  # Strict security rules
storage.rules                    # Storage security rules
firestore.indexes.json           # Required composite indexes
```

---

## Setup Guide

### 1. Prerequisites

```bash
flutter --version   # 3.19+
node --version      # 18+
firebase --version  # 13+
```

### 2. Create a Flutter project shell

```bash
flutter create ekora_app --org com.yourcompany --platforms android,ios
# Then copy this lib/ folder into it, replacing the generated one.
```

### 3. Firebase Setup

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login and configure
firebase login
flutterfire configure --project YOUR_FIREBASE_PROJECT_ID
```

This generates `lib/firebase_options.dart` with your real credentials.  
**Delete the placeholder `firebase_options.dart` and use the generated one.**

### 4. Enable Firebase services

In the Firebase Console:

- **Authentication** → Enable: Email/Password, Google, Facebook
- **Firestore** → Create database (production mode)
- **Storage** → Enable
- **Cloud Messaging** → Enable
- **Crashlytics** → Enable
- **Cloud Functions** → Upgrade to Blaze plan (required)

### 5. Google Sign-In

1. In Firebase Console → Authentication → Sign-in method → Google → Enable
2. Download `google-services.json` → place in `android/app/`
3. Download `GoogleService-Info.plist` → place in `ios/Runner/`
4. Add your SHA-1 fingerprint in Firebase Console → Project Settings → Android app

```bash
# Get SHA-1 (debug)
cd android && ./gradlew signingReport
```

### 6. Facebook Sign-In

1. Create app at developers.facebook.com
2. Add Android/iOS platforms
3. In Firebase Console → Auth → Facebook → enter App ID + App Secret
4. Follow `flutter_facebook_auth` setup: https://pub.dev/packages/flutter_facebook_auth

### 7. Android Setup

In `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        applicationId "com.yourcompany.ekora_app"
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

In `android/app/src/main/AndroidManifest.xml`, add inside `<application>`:
```xml
<!-- FCM -->
<service android:name="com.google.firebase.messaging.FirebaseMessagingService"
         android:exported="true">
  <intent-filter>
    <action android:name="com.google.firebase.MESSAGING_EVENT"/>
  </intent-filter>
</service>

<!-- Internet permission -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

### 8. iOS Setup

In `ios/Runner/Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>eKora needs access to upload your profile photo.</string>
<key>NSCameraUsageDescription</key>
<string>eKora needs camera access for profile photos.</string>
```

### 9. Install dependencies & run

```bash
flutter pub get
flutter run
```

### 10. Deploy Cloud Functions

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### 11. Deploy Firestore rules and indexes

```bash
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only storage
```

---

## Firestore Schema

### `users/{uid}`
```
{
  uid: string,
  email: string,
  username: string,           // unique display name
  displayName: string?,
  photoUrl: string?,          // Firebase Storage URL
  phoneNumber: string?,       // Egyptian format: +201xxxxxxxxx
  bio: string?,
  role: "user" | "admin",
  fcmToken: string?,          // For push notifications
  wins: number,
  losses: number,
  totalMatches: number,
  points: number,
  globalRank: number,
  banned: boolean?,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### `users/{uid}/notifications/{notifId}`
```
{
  title: string,
  body: string,
  data: map,
  read: boolean,
  createdAt: Timestamp
}
```

### `tournaments/{tournamentId}`
```
{
  title: string,
  description: string,
  game: string,               // "FIFA", "PUBG Mobile", etc.
  format: string,             // "1v1", "5v5", "Battle Royale"
  status: "upcoming" | "live" | "finished" | "cancelled",
  entryFee: number,           // EGP (0 = free)
  prizePool: number,          // EGP
  maxParticipants: number,
  currentParticipants: number,
  startDate: Timestamp,
  endDate: Timestamp,
  imageUrl: string?,
  createdBy: string,          // admin uid
  participantIds: string[],   // uid[]
  pendingApprovalIds: string[],
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### `tournaments/{tournamentId}/participants/{uid}`
```
{
  userId: string,
  paymentId: string?,
  joinedAt: Timestamp,
  status: "active" | "disqualified"
}
```

### `payments/{paymentId}`
```
{
  userId: string,
  tournamentId: string,
  tournamentTitle: string,
  amount: number,             // EGP
  method: "vodafone_cash" | "fawry" | "credit_card",
  status: "pending" | "completed" | "failed" | "refunded",
  transactionId: string?,     // Provider reference
  failureReason: string?,
  createdAt: Timestamp,
  completedAt: Timestamp?
}
```

---

## Payment Integration Guide

### Vodafone Cash (Egypt)
1. Register at Vodafone Business: https://business.vodafone.com.eg
2. Obtain Merchant ID + API credentials
3. Replace `initiatePayment` stub in `functions/index.js` with real API call
4. Implement webhook endpoint for payment confirmation callbacks

### Fawry
1. Register at developer.fawrystaging.com
2. Obtain merchantCode + secureKey
3. Replace Fawry stub in `functions/index.js`
4. Set up callback URL for payment notifications

### Stripe (Credit/Debit Cards)
```bash
npm install stripe --prefix functions
```
Then in `functions/index.js`, replace the credit card stub with:
```js
const stripe = require('stripe')(functions.config().stripe.secret);
const intent = await stripe.paymentIntents.create({
  amount: Math.round(amount * 100), // piastres
  currency: 'egp',
  metadata: { userId, tournamentId }
});
```

---

## Security Model

| Resource | Read | Write | Notes |
|---|---|---|---|
| `users/*` | Any auth user | Owner (limited fields) / Admin | Role field is immutable by user |
| `tournaments/*` | Any auth user | Admin only | User can join (limited update) |
| `payments/*` | Owner / Admin | Cloud Functions only | Status never writable by client |
| `storage/avatars` | Any auth user | Owner only | 5 MB limit, images only |
| `storage/tournament_images` | Any auth user | Admin only | 5 MB limit |

---

## Environment Config

Create `.env.dev` and `.env.prod` for different Firebase projects:

```bash
# Set Firebase Functions config
firebase functions:config:set stripe.secret="sk_live_..." --project prod
firebase functions:config:set vodafone.merchant_id="..." --project prod
firebase functions:config:set fawry.merchant_code="..." --project prod
```

---

## Adding Cairo Font

Download from Google Fonts: https://fonts.google.com/specimen/Cairo

Place TTF files in `assets/fonts/`:
- `Cairo-Regular.ttf`
- `Cairo-Medium.ttf`
- `Cairo-SemiBold.ttf`
- `Cairo-Bold.ttf`

These are already declared in `pubspec.yaml`.

---

## Running Firebase Emulators (Local Dev)

```bash
firebase emulators:start
```

Then in `main.dart`, add before `runApp()`:
```dart
if (kDebugMode) {
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
}
```

---

## Useful Commands

```bash
# Run on device
flutter run --release

# Build APK
flutter build apk --release

# Build App Bundle (Play Store)
flutter build appbundle --release

# Build iOS
flutter build ipa --release

# Analyze code
flutter analyze

# Run tests
flutter test

# Deploy everything to Firebase
firebase deploy
```
