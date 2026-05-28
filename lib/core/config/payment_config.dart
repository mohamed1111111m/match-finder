/// Static payment account configuration.
/// Replace placeholder numbers with real production values before launch.
class PaymentConfig {
  PaymentConfig._();

  // ── InstaPay ──────────────────────────────────────────────────────────────
  static const String instaPayIpa = 'mohamed.abdelftah1974@instapay';
  static const String instaPayName = 'إيكورا للرياضة';

  // ── Orange Cash ───────────────────────────────────────────────────────────
  static const String orangeCashNumber = '01202565544'; // ← replace
  static const String orangeCashName = 'إيكورا';

  // ── Vodafone Cash ─────────────────────────────────────────────────────────
  static const String vodafoneCashNumber = '0100000000'; // ← replace
  static const String vodafoneCashName = 'إيكورا';

  // ── Commission ────────────────────────────────────────────────────────────
  /// Platform commission added on top of the venue's base price.
  /// e.g. 10.0 means the buyer pays base + 10% to the platform.
  static const double commissionPercent = 10.0;

  /// Applies commission to a base amount and returns the total the buyer pays.
  static double applyCommission(double base) =>
      base + (base * commissionPercent / 100);

  /// Returns the commission amount (what the platform earns) from a base price.
  static double commissionAmount(double base) =>
      base * commissionPercent / 100;

  // ── Expiry ────────────────────────────────────────────────────────────────
  /// How long the user has to complete payment before the booking expires.
  static const Duration paymentExpiry = Duration(minutes: 15);
}
