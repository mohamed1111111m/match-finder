import 'dart:async';
import 'dart:io';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/payment_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/booking_entity.dart';
import '../providers/venue_provider.dart';

// ── Brand colours ─────────────────────────────────────────────────────────────
const _instaPayColor     = Color(0xFF00897B);
const _orangeCashColor   = Color(0xFFFF6D00);
const _vodafoneCashColor = Color(0xFFE53935);

class BookingPaymentScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const BookingPaymentScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingPaymentScreen> createState() =>
      _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends ConsumerState<BookingPaymentScreen> {
  String? _selectedMethod;
  bool _appOpened = false;
  File? _receiptFile;
  Timer? _ticker;
  int _remainingSeconds = PaymentConfig.paymentExpiry.inSeconds;
  bool _timerSynced = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) _remainingSeconds--;
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTimer(DateTime createdAt) {
    if (_timerSynced) return;
    _timerSynced = true;
    final elapsed = DateTime.now().difference(createdAt).inSeconds;
    final remaining = (PaymentConfig.paymentExpiry.inSeconds - elapsed)
        .clamp(0, PaymentConfig.paymentExpiry.inSeconds);
    if (mounted) setState(() => _remainingSeconds = remaining);
  }

  String get _timerDisplay {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get _isExpired => _remainingSeconds <= 0;

  // ── Open payment app ───────────────────────────────────────────────────────

  Future<void> _dialUssd(String method) async {
    setState(() => _appOpened = true);
    final Uri uri;
    switch (method) {
      case AppConstants.paymentVodafoneCash:
        uri = Uri.parse('tel:*9%23');
      case AppConstants.paymentOrangeCash:
        uri = Uri.parse('tel:*880%23');
      default:
        return;
    }
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('مش قادر يفتح الهاتف — اتصل يدوي'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _openStore(String method) async {
    setState(() => _appOpened = true);
    final Uri? uri;
    switch (method) {
      case AppConstants.paymentVodafoneCash:
        uri = Uri.parse('market://details?id=com.vodafone.myvodafone');
      case AppConstants.paymentOrangeCash:
        uri = Uri.parse('market://details?id=com.orange.orangemoney');
      default:
        uri = null;
    }
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final web = Uri.parse(
          method == AppConstants.paymentVodafoneCash
              ? 'https://play.google.com/store/apps/details?id=com.vodafone.myvodafone'
              : 'https://play.google.com/store/apps/details?id=com.orange.orangemoney',
        );
        if (await canLaunchUrl(web)) {
          await launchUrl(web, mode: LaunchMode.externalApplication);
        }
      }
    } catch (_) {}
  }

  // ── Pick receipt image ─────────────────────────────────────────────────────

  Future<void> _pickReceipt(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked == null || !mounted) return;
      setState(() => _receiptFile = File(picked.path));
    } catch (_) {}
  }

  void _showReceiptPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('التقط صورة'),
              onTap: () { Navigator.pop(ctx); _pickReceipt(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('اختر من المعرض'),
              onTap: () { Navigator.pop(ctx); _pickReceipt(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  // ── Confirm payment ────────────────────────────────────────────────────────

  Future<void> _confirmPayment() async {
    if (_selectedMethod == null) return;
    if (_receiptFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('لازم ترفع صورة الإيصال قبل التأكيد'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final ok = await ref
        .read(bookingNotifierProvider.notifier)
        .submitPaymentConfirmation(
          bookingId: widget.bookingId,
          paymentMethod: _selectedMethod!,
          receiptFile: _receiptFile!,
        );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حصل خطأ — حاول مرة تانية'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bookingAsync =
        ref.watch(bookingByIdStreamProvider(widget.bookingId));
    final bookingState = ref.watch(bookingNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('إتمام الدفع'),
        elevation: 0,
      ),
      body: bookingAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('خطأ: $e')),
        data: (booking) {
          if (booking == null) {
            return const Center(child: Text('الحجز غير موجود'));
          }

          WidgetsBinding.instance.addPostFrameCallback(
              (_) => _syncTimer(booking.createdAt));

          if (booking.isPendingVerification) {
            return _PendingView(booking: booking);
          }
          if (booking.isConfirmed) {
            return _ConfirmedView(booking: booking);
          }
          if (booking.isCancelled) {
            return _CancelledView(rejectionReason: booking.rejectionReason);
          }
          if (_isExpired || booking.isExpired) {
            return const _ExpiredView();
          }

          // ── Main payment flow ──────────────────────────────────────────
          return SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(16, 12, 16, 160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary + countdown
                _SummaryHeader(
                  booking: booking,
                  timerDisplay: _timerDisplay,
                  remaining: _remainingSeconds,
                ).animate().fadeIn(),

                const SizedBox(height: 20),

                // Step 1 — choose method
                _StepLabel(
                  number: 1,
                  label: 'اختار طريقة الدفع',
                ),
                const SizedBox(height: 10),

                _MethodCard(
                  method: AppConstants.paymentInstaPay,
                  label: 'إنستاباي',
                  subtitle: 'تحويل فوري من أي بنك',
                  color: _instaPayColor,
                  icon: Icons.account_balance_rounded,
                  selected:
                      _selectedMethod == AppConstants.paymentInstaPay,
                  onTap: () => setState(() {
                    _selectedMethod = AppConstants.paymentInstaPay;
                    _appOpened = false;
                  }),
                ).animate(delay: 60.ms).fadeIn().slideX(begin: 0.04),

                const SizedBox(height: 8),

                _MethodCard(
                  method: AppConstants.paymentOrangeCash,
                  label: 'أورانج كاش',
                  subtitle: 'اتصل بـ *880# أو افتح التطبيق',
                  color: _orangeCashColor,
                  icon: Icons.phonelink_ring_rounded,
                  selected:
                      _selectedMethod == AppConstants.paymentOrangeCash,
                  onTap: () => setState(() {
                    _selectedMethod = AppConstants.paymentOrangeCash;
                    _appOpened = false;
                  }),
                ).animate(delay: 90.ms).fadeIn().slideX(begin: 0.04),

                const SizedBox(height: 8),

                _MethodCard(
                  method: AppConstants.paymentVodafoneCash,
                  label: 'فودافون كاش',
                  subtitle: 'اتصل بـ *9# أو افتح التطبيق',
                  color: _vodafoneCashColor,
                  icon: Icons.sim_card_rounded,
                  selected:
                      _selectedMethod == AppConstants.paymentVodafoneCash,
                  onTap: () => setState(() {
                    _selectedMethod = AppConstants.paymentVodafoneCash;
                    _appOpened = false;
                  }),
                ).animate(delay: 120.ms).fadeIn().slideX(begin: 0.04),

                // Step 2 — instructions (visible when method selected)
                if (_selectedMethod != null) ...[
                  const SizedBox(height: 20),
                  _StepLabel(
                    number: 2,
                    label: 'تفاصيل التحويل',
                  ),
                  const SizedBox(height: 10),
                  _InstructionsPanel(
                    method: _selectedMethod!,
                    amount: booking.totalCost,
                    referenceId: widget.bookingId,
                    onDial: () => _dialUssd(_selectedMethod!),
                    onOpenStore: () => _openStore(_selectedMethod!),
                    appOpened: _appOpened,
                  ).animate().fadeIn().slideY(begin: 0.06),
                ],

                // Step 3 — confirm
                if (_selectedMethod != null) ...[
                  const SizedBox(height: 20),
                  _StepLabel(number: 3, label: 'أكّد إتمام الدفع'),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: AppColors.primary, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'بعد ما تحوّل المبلغ، ارجع هنا واضغط الزر في الأسفل.',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                                height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Receipt upload
                  GestureDetector(
                    onTap: _showReceiptPicker,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _receiptFile != null
                              ? AppColors.success
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: _receiptFile != null
                          ? Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    _receiptFile!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('تم رفع الإيصال ✓',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.success,
                                              fontSize: 13)),
                                      const SizedBox(height: 4),
                                      TextButton(
                                        onPressed: _showReceiptPicker,
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text('تغيير الصورة',
                                            style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.upload_rounded,
                                    color: AppColors.primary, size: 28),
                                const SizedBox(height: 6),
                                const Text('ارفع صورة الإيصال',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                const Text('إجباري — بدون إيصال مش هينفع التأكيد',
                                    style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11)),
                              ],
                            ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),

      // ── Bottom button ──────────────────────────────────────────────────────
      bottomNavigationBar: bookingAsync.maybeWhen(
        data: (booking) {
          if (booking == null ||
              booking.isPendingVerification ||
              booking.isConfirmed ||
              booking.isCancelled ||
              _isExpired ||
              booking.isExpired ||
              _selectedMethod == null) {
            return null;
          }
          final canSubmit = _receiptFile != null;
          return SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ElevatedButton.icon(
                onPressed: (bookingState.isLoading || !canSubmit) ? null : _confirmPayment,
                icon: bookingState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Icon(Icons.check_circle_outline_rounded,
                        size: 20),
                label: Text(
                  bookingState.isLoading
                      ? 'جاري الإرسال...'
                      : !canSubmit
                          ? 'ارفع الإيصال أولاً'
                          : 'دفعت — أرسل للمراجعة',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }
}

// ── Summary header ────────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  final BookingEntity booking;
  final String timerDisplay;
  final int remaining;
  const _SummaryHeader(
      {required this.booking,
      required this.timerDisplay,
      required this.remaining});

  @override
  Widget build(BuildContext context) {
    final urgent = remaining < 180;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primary.withValues(alpha: 0.85)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          // Venue + times
          Row(children: [
            const Icon(Icons.sports_soccer_rounded,
                color: Colors.white70, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                booking.venueName,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.calendar_today_rounded,
                color: Colors.white54, size: 14),
            const SizedBox(width: 4),
            Text(booking.dateText,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13)),
            const SizedBox(width: 12),
            const Icon(Icons.schedule_rounded,
                color: Colors.white54, size: 14),
            const SizedBox(width: 4),
            Text('${booking.startTime} – ${booking.endTime}',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13)),
          ]),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Total
              Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('الإجمالي',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 11)),
                Text('${booking.totalCost.toInt()} جنيه',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22)),
              ]),
              // Timer
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: urgent
                      ? Colors.red.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: urgent
                          ? Colors.red.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Icon(
                      urgent
                          ? Icons.timer_off_rounded
                          : Icons.timer_outlined,
                      color: urgent ? Colors.redAccent : Colors.white,
                      size: 16),
                  const SizedBox(width: 6),
                  Text(timerDisplay,
                      style: TextStyle(
                          color:
                              urgent ? Colors.redAccent : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          fontFamily: 'monospace')),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Step label ────────────────────────────────────────────────────────────────

class _StepLabel extends StatelessWidget {
  final int number;
  final String label;
  const _StepLabel({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text('$number',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
        ),
      ),
      const SizedBox(width: 10),
      Text(label,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800)),
    ]);
  }
}

// ── Method selection card ──────────────────────────────────────────────────────

class _MethodCard extends StatelessWidget {
  final String method, label, subtitle;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.method,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.07)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? color
                : Theme.of(context).colorScheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted)),
              ],
            ),
          ),
          if (selected)
            Icon(Icons.check_circle_rounded, color: color, size: 22)
          else
            Icon(Icons.radio_button_unchecked_rounded,
                color: Theme.of(context).colorScheme.outline,
                size: 22),
        ]),
      ),
    );
  }
}

// ── Payment instructions panel ────────────────────────────────────────────────

class _InstructionsPanel extends StatelessWidget {
  final String method;
  final double amount;
  final String referenceId;
  final VoidCallback onDial;
  final VoidCallback onOpenStore;
  final bool appOpened;

  const _InstructionsPanel({
    required this.method,
    required this.amount,
    required this.referenceId,
    required this.onDial,
    required this.onOpenStore,
    required this.appOpened,
  });

  Color get _color {
    switch (method) {
      case AppConstants.paymentInstaPay:   return _instaPayColor;
      case AppConstants.paymentOrangeCash: return _orangeCashColor;
      default:                             return _vodafoneCashColor;
    }
  }

  String get _shortRef =>
      referenceId.substring(0, 8).toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment details to copy
          if (method == AppConstants.paymentInstaPay)
            _CopyRow(
                label: 'عنوان IPA',
                value: PaymentConfig.instaPayIpa,
                color: _color)
          else
            _CopyRow(
              label: method == AppConstants.paymentOrangeCash
                  ? 'رقم أورانج كاش'
                  : 'رقم فودافون كاش',
              value: method == AppConstants.paymentOrangeCash
                  ? PaymentConfig.orangeCashNumber
                  : PaymentConfig.vodafoneCashNumber,
              color: _color,
            ),
          const SizedBox(height: 8),
          _CopyRow(
              label: 'المبلغ',
              value: '${amount.toInt()} جنيه',
              color: _color),
          const SizedBox(height: 8),
          _CopyRow(
              label: 'رقم الحجز (المرجع)',
              value: _shortRef,
              color: _color),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Open app / dial button
          if (method == AppConstants.paymentInstaPay)
            _InfoNote(
              icon: Icons.info_outline_rounded,
              text:
                  'إنستاباي متاح في تطبيق البنك بتاعك. افتحه وابحث عن "إنستاباي"، ثم حوّل للـ IPA أعلاه.',
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Primary: USSD dial
                _ActionButton(
                  label: method == AppConstants.paymentOrangeCash
                      ? 'اتصل بـ *880# (أورانج كاش)'
                      : 'اتصل بـ *9# (فودافون كاش)',
                  icon: Icons.call_rounded,
                  color: _color,
                  onTap: onDial,
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'أو',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                // Secondary: open Play Store
                _ActionButton(
                  label: 'فتح التطبيق من Play Store',
                  icon: Icons.open_in_new_rounded,
                  color: _color,
                  outlined: true,
                  onTap: onOpenStore,
                ),
              ],
            ),

          if (appOpened) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(children: [
                Icon(Icons.check_rounded,
                    color: AppColors.success, size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'حوّل المبلغ وارجع هنا واضغط "دفعت"',
                    style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _CopyRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _CopyRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
      GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('تم نسخ "$value"'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ));
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.copy_rounded, size: 16, color: color),
        ),
      ),
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoNote({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.info, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.info,
                    height: 1.5)),
          ),
        ],
      ),
    );
  }
}

// ── Status screens ────────────────────────────────────────────────────────────

class _PendingView extends StatelessWidget {
  final BookingEntity booking;
  const _PendingView({required this.booking});

  Future<void> _viewReceipt(BuildContext context) async {
    final url = booking.receiptUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح الإيصال')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Colored header banner — eliminates the white flash
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              border: Border(
                bottom: BorderSide(
                    color: AppColors.warning.withValues(alpha: 0.2))),
            ),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_top_rounded,
                      color: AppColors.warning, size: 46),
                ).animate().scale(
                    begin: const Offset(0.6, 0.6),
                    curve: Curves.easeOutBack),
                const SizedBox(height: 18),
                const Text('طلبك قيد المراجعة',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  'استلمنا تأكيد دفعك لـ ${booking.venueName}.\n'
                  'سيتم التأكيد خلال 5–30 دقيقة عادةً.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      height: 1.65),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              children: [
                _DetailRow(Icons.stadium_rounded, booking.venueName),
                _DetailRow(Icons.calendar_today_rounded, booking.dateText),
                _DetailRow(Icons.schedule_rounded,
                    '${booking.startTime} — ${booking.endTime}'),
                _DetailRow(Icons.payment_rounded, booking.paymentMethodAr),

                if (booking.receiptUrl != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _viewReceipt(context),
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text('عرض الإيصال المرفوع'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.home_outlined, size: 18),
                    label: const Text('العودة للرئيسية'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmedView extends StatefulWidget {
  final BookingEntity booking;
  const _ConfirmedView({required this.booking});

  @override
  State<_ConfirmedView> createState() => _ConfirmedViewState();
}

class _ConfirmedViewState extends State<_ConfirmedView> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _saveReceiptPdf() async {
    final b = widget.booking;
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(32),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('إيصال حجز ملعب',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 16),
              _pdfRow('رقم الحجز', b.id.substring(0, 12).toUpperCase()),
              _pdfRow('الملعب', b.venueName),
              _pdfRow('التاريخ', b.dateText),
              _pdfRow('الميعاد', '${b.startTime} – ${b.endTime}'),
              _pdfRow('المبلغ', '${b.totalCost.toInt()} جنيه'),
              _pdfRow('طريقة الدفع', b.paymentMethodAr),
              _pdfRow('الحالة', 'مؤكد'),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text('شكراً لاستخدام eKora',
                  style: const pw.TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'booking_${b.id.substring(0, 8)}.pdf',
    );
  }

  pw.Widget _pdfRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          children: [
            pw.Text('$label: ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold,
                    fontSize: 13)),
            pw.Text(value, style: const pw.TextStyle(fontSize: 13)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Confetti
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 30,
          colors: const [
            AppColors.primary, AppColors.success,
            AppColors.accent, AppColors.info,
            Colors.purple, Colors.orange,
          ],
        ),

        // Content
        SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 56),
              )
                  .animate()
                  .scale(
                      begin: const Offset(0.5, 0.5),
                      curve: Curves.easeOutBack,
                      duration: 600.ms)
                  .fadeIn(),

              const SizedBox(height: 20),
              const Text('تم تأكيد الحجز! 🎉',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w900))
                  .animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),

              const SizedBox(height: 8),
              Text(
                'حجزك في ${widget.booking.venueName} مؤكد ومدفوع.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14, height: 1.6),
              ).animate(delay: 300.ms).fadeIn(),

              const SizedBox(height: 28),

              // Receipt card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outline),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _DetailRow(Icons.tag_rounded,
                        'رقم الحجز: ${widget.booking.id.substring(0, 8).toUpperCase()}'),
                    _DetailRow(Icons.stadium_outlined,
                        widget.booking.venueName),
                    _DetailRow(Icons.calendar_today_rounded,
                        widget.booking.dateText),
                    _DetailRow(Icons.schedule_rounded,
                        '${widget.booking.startTime} — ${widget.booking.endTime}'),
                    _DetailRow(Icons.payments_outlined,
                        '${widget.booking.totalCost.toInt()} جنيه'),
                    _DetailRow(Icons.account_balance_wallet_outlined,
                        widget.booking.paymentMethodAr),
                  ],
                ),
              ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 24),

              // Save PDF
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _saveReceiptPdf,
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                  label: const Text('حفظ الإيصال PDF',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ).animate(delay: 500.ms).fadeIn(),

              const SizedBox(height: 12),

              // Go home
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_rounded, size: 18),
                  label: const Text('العودة للرئيسية',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ).animate(delay: 550.ms).fadeIn(),
            ],
          ),
        ),
      ],
    );
  }
}

class _CancelledView extends StatelessWidget {
  final String? rejectionReason;
  const _CancelledView({this.rejectionReason});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel_rounded,
                color: AppColors.error, size: 80),
            const SizedBox(height: 18),
            const Text('تم رفض الحجز',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'للأسف الدفع لم يتم تأكيده.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 14, height: 1.6),
            ),
            if (rejectionReason != null && rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'السبب: $rejectionReason',
                        style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'تواصل مع الدعم لمزيد من المساعدة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home_outlined, size: 18),
                label: const Text('العودة للرئيسية'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpiredView extends StatelessWidget {
  const _ExpiredView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_off_rounded,
                color: AppColors.textMuted, size: 80),
            const SizedBox(height: 18),
            const Text('انتهت مهلة الدفع',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'مرت أكتر من 15 دقيقة.\nارجع وابدأ حجز جديد من صفحة الملعب.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  height: 1.6),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/venues'),
                icon: const Icon(Icons.sports_soccer_rounded, size: 18),
                label: const Text('احجز ملعب جديد'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home_outlined, size: 18),
                label: const Text('العودة للرئيسية'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.center,
          children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textMuted)),
      ]),
    );
  }
}
