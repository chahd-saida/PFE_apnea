# SleepApnea Detect

Flutter mobile/web app for sleep-apnea monitoring with patient and doctor workflows.

## Tech stack

- Flutter (UI)
- Firebase Authentication
- Cloud Firestore
- GoRouter (navigation + guards)
- Provider (state management)

## Setup

1. Clone the repository.
2. Install dependencies:
   - `flutter pub get`
3. Configure Firebase (FlutterFire CLI):
   - `dart pub global activate flutterfire_cli`
   - `flutterfire configure`
4. Run on web:
   - `flutter run -d chrome`

## Architecture overview

- `lib/services/`: service layer (Firebase, settings, monitoring).
- `lib/providers/`: app state (`AuthProvider`, `ThemeProvider`).
- `lib/screens/`: feature UI screens.
- `main.dart`: app bootstrap, provider wiring, GoRouter setup.

Role-based route guards are handled in GoRouter redirects and read from `AuthProvider.role`.

All Firestore reads/writes are routed through `FirebaseService`.

## Known limitations

- Desktop Firebase config (macOS/Windows/Linux) still uses placeholders in `firebase_options.dart`.
- Realtime monitoring currently uses mocked stream data; BLE/SDK integration is TODO in `MonitoringService`.

## Adding a new screen

1. Create a UI screen in `lib/screens/`.
2. Add data access methods to `FirebaseService` if backend is needed.
3. Add provider state only if shared across multiple screens.
4. Register a route in `createRouter(...)` in `main.dart`.
5. Add/update widget tests for route behavior or primary interactions.
