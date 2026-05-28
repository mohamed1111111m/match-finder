import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tournaments/presentation/providers/tournament_provider.dart';
import '../providers/payment_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const PaymentScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedMethod = 'vodafone_cash';
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _proceed() async {
    final tournament =
        ref.read(tournamentDetailProvider(widget.tournamentId)).valueOrNull;
    final user = ref.read(currentUserProvider);
    if (tournament == null || user == null) return;

    final notifier = ref.read(paymentNotifierProvider.notifier);

    final paymentId = await notifier.initiatePayment(
      userId: user.uid,
      tournamentId: widget.tournamentId,
      tournamentTitle: tournament.title,
      amount: tournament.entryFee,
      method: _selectedMethod,
      phoneNumber:
          _selectedMethod == 'vodafone_cash' ? _phoneCtrl.text.trim() : null,
    );

    if (paymentId == null || !mounted) return;

    final confirmed =
        await _showPaymentConfirmationDialog(tournament.entryFee, paymentId);
    if (!confirmed || !mounted) return;

    final payState = ref.read(paymentNotifierProvider);
    final verified = await ref
        .read(paymentNotifierProvider.notifier)
        .verifyPayment(
          paymentId: paymentId,
          transactionId: payState.transactionId ?? '',
        );

    if (verified && mounted) {
      final joinNotifier =
          ref.read(joinTournamentProvider(widget.tournamentId).notifier);
      await joinNotifier.join(widget.tournamentId, user.uid,
          paymentId: paymentId);

      if (mounted) _showSuccessDialog();
    }
  }

  Future<bool> _showPaymentConfirmationDialog(
      double amount, String paymentId) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('تأكيد الدفع'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المبلغ: ${amount.egp}'),
                const SizedBox(height: 8),
                Text('طريقة الدفع: ${_methodName(_selectedMethod)}'),
                const SizedBox(height: 8),
                Text('رقم المرجع: $paymentId',
                    style: Theme.of(ctx).textTheme.bodySmall),
                const SizedBox(height: 16),
                _selectedMethod == 'vodafone_cash'
                    ? Text(
                        'ادفع ${amount.egp} على *9*111# (فودافون كاش)\nالمرجع: $paymentId')
                    : _selectedMethod == 'fawry'
                        ? Text(
                            'ادفع في أي فرع فوري\nكود: $paymentId\nالمبلغ: ${amount.egp}')
                        : const Text('هذا وضع تجريبي - سيتم محاكاة الدفع.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('دفعت'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text('تم الدفع بنجاح! 🎉'),
          ],
        ),
        content: const Text(
            'تم التحقق من دفعتك وانضممت للبطولة. بالتوفيق!'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('تمام'),
          ),
        ],
      ),
    );
  }

  String _methodName(String method) {
    switch (method) {
      case 'vodafone_cash': return 'فودافون كاش';
      case 'fawry':         return 'فوري';
      case 'credit_card':   return 'كارت بنكي';
      default:              return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync =
        ref.watch(tournamentDetailProvider(widget.tournamentId));
    final paymentState = ref.watch(paymentNotifierProvider);

    ref.listen(paymentNotifierProvider, (_, next) {
      if (next.isFailed && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(next.error!),
              backgroundColor: AppColors.error),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('الدفع')),
      body: tournamentAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (tournament) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tournament summary
              _TournamentSummaryCard(
                title: tournament.title,
                amount: tournament.entryFee,
              ).animate().fadeIn(),

              const SizedBox(height: 24),

              Text('اختر طريقة الدفع',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700))
                  .animate()
                  .fadeIn(delay: 100.ms),

              const SizedBox(height: 12),

              _PaymentMethodCard(
                method: 'vodafone_cash',
                label: 'فودافون كاش',
                subtitle: 'دفع فوري على الموبايل',
                icon: Icons.phone_android,
                color: AppColors.vodafoneColor,
                selected: _selectedMethod == 'vodafone_cash',
                onTap: () => setState(() => _selectedMethod = 'vodafone_cash'),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 10),

              _PaymentMethodCard(
                method: 'fawry',
                label: 'فوري',
                subtitle: 'ادفع في أي فرع فوري',
                icon: Icons.store_outlined,
                color: AppColors.fawryColor,
                selected: _selectedMethod == 'fawry',
                onTap: () => setState(() => _selectedMethod = 'fawry'),
              ).animate().fadeIn(delay: 280.ms),

              const SizedBox(height: 10),

              _PaymentMethodCard(
                method: 'credit_card',
                label: 'كارت بنكي',
                subtitle: 'فيزا، ماستركارد',
                icon: Icons.credit_card,
                color: AppColors.cardColor,
                selected: _selectedMethod == 'credit_card',
                onTap: () => setState(() => _selectedMethod = 'credit_card'),
              ).animate().fadeIn(delay: 360.ms),

              if (_selectedMethod == 'vodafone_cash') ...[
                const SizedBox(height: 20),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم فودافون كاش',
                    hintText: '010xxxxxxxx',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ).animate().fadeIn(delay: 100.ms),
              ],

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('إجمالي المبلغ',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    tournament.entryFee.egp,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              AppButton(
                label: paymentState.isLoading ? 'جاري المعالجة...' : 'ادفع دلوقتي',
                onPressed: paymentState.isLoading ? null : _proceed,
                isLoading: paymentState.isLoading,
                icon: Icons.lock_outlined,
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'الدفع آمن ومشفر',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TournamentSummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  const _TournamentSummaryCard({required this.title, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkCard, AppColors.darkElevated],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.emoji_events,
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('رسوم اشتراك البطولة',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.textSecondary)),
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Text(
            amount.egp,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String method, label, subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.method,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Theme.of(context).colorScheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : Colors.transparent,
                border: Border.all(
                  color: selected ? color : AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
