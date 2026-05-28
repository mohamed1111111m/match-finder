/// Runtime configuration. isDemoMode is set to true automatically
/// when Firebase is unavailable (no real google-services.json configured).
/// Switch to false once you run `flutterfire configure`.
class AppConfig {
  static bool _demoMode = false;

  static bool get isDemoMode => _demoMode;

  static void enableDemoMode() {
    _demoMode = true;
  }

  // ── Demo credentials ───────────────────────────────────────────────────
  // Use these to log in when running in demo mode.
  static const String demoUserEmail    = 'player@ekora.demo';
  static const String demoUserPassword = 'demo1234';
  static const String demoAdminEmail   = 'admin@ekora.demo';
  static const String demoAdminPassword = 'admin1234';
}
