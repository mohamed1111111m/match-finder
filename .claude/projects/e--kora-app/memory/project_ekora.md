---
name: eKora App Project
description: Full Flutter + Firebase tournament platform for Egypt — architecture, stack, and key decisions
type: project
---

Production Flutter app built from scratch in e:/kora app.

**Why:** User asked for a complete, production-ready competitive gaming tournament platform for Egypt.

**Stack:** Flutter 3 + Riverpod 2 (StateNotifier pattern, no codegen) + GoRouter 13 + Firebase full suite + Clean Architecture (feature-based). Payments via Cloud Functions (Vodafone Cash / Fawry / Card stubs ready for real API wiring).

**61 Dart files across 7 features.** Never commit firebase_options.dart, google-services.json, or GoogleService-Info.plist.

**How to apply:** When continuing this project, the app needs `flutter pub get` before any errors clear. All "package not found" IDE errors are expected until packages are fetched.
