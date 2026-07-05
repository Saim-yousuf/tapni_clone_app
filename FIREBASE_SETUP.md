# Firebase Setup (FCM Push Notifications)

Push notifications require Firebase configuration on both the app and backend.

### Automated notifications

| Event | Recipient | Channel |
|-------|-----------|---------|
| New catalog/menu order | Business (Pro) | orders |
| Order status update | Customer | orders |
| Card/QR scan | Business (Pro) | leads |
| Contact saved / exchanged | Both users | leads |
| Subscription approved / rejected | User | account |
| Subscription expiring (3 & 1 day) | Pro user | account |

## 1. Firebase Console

1. Create a project at [Firebase Console](https://console.firebase.google.com/)
2. Add an **Android** app with package name: `com.example.tapni_app`
3. Download `google-services.json` → place in `android/app/google-services.json`
4. Add an **iOS** app → download `GoogleService-Info.plist` → add to Xcode Runner target
5. Enable **Cloud Messaging** in the project

## 2. Flutter app config

**Option A — Manual (Android only, if you already have `google-services.json`):**

Values are in `lib/firebase_options.dart` (synced from your `google-services.json`).

**Option B — FlutterFire CLI (recommended for iOS + all platforms):**

1. Install Firebase CLI (required by FlutterFire):

```powershell
npm install -g firebase-tools
firebase login
```

2. From the `tapni_app` folder:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Select project `barqody-2fb4e` when prompted. This overwrites `lib/firebase_options.dart`.

Rebuild the app after adding `google-services.json`.

## 3. Backend (Firebase Admin)

1. Firebase Console → Project Settings → Service accounts → **Generate new private key**
2. Save the JSON file locally (do **not** commit it)

**Local development** — add to `tapni-backend/.env`:

```env
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
```

**Production (Vercel etc.)** — paste the entire JSON as one line:

```env
FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account",...}
```

Restart the backend after setting env vars.

## 4. Test flow

1. Login on two devices (or emulator + phone) — business Pro user + customer
2. Customer places an order → business receives push
3. Business updates status → customer receives push
4. Scan a Pro user's card → they receive a scan notification
5. Exchange contacts → both users receive push
6. Admin approves/rejects subscription → user receives push
7. Tap notification → opens the relevant screen (order, contacts, analytics, or subscription)

## API endpoints

| Method | Path | Body |
|--------|------|------|
| POST | `/api/user/auth/fcm-token` | `{ "token": "...", "platform": "android" }` |
| DELETE | `/api/user/auth/fcm-token` | `{ "token": "..." }` |

Token is synced automatically on login and app launch when authenticated.
