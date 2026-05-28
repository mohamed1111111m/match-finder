import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/matchmaking_provider.dart';

class CreateSessionScreen extends ConsumerStatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  ConsumerState<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends ConsumerState<CreateSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  String _sport = 'football';
  String _city = 'الإسماعيلية';
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String _time = '18:00';
  int _totalPlayers = 10;
  int _currentPlayers = 5;

  final _sports = [
    ('football',   '⚽ كورة قدم'),
    ('padel',      '🎾 بادل'),
    ('basketball', '🏀 سلة'),
  ];

  final _cities = [
    'الإسماعيلية', 'بورسعيد', 'السويس', 'القنطرة',
    'القاهرة', 'الإسكندرية', 'المنصورة', 'طنطا',
  ];
  final _times = [
    '06:00','06:30','07:00','07:30','08:00','08:30','09:00','09:30',
    '10:00','10:30','11:00','11:30','12:00','12:30','13:00','13:30',
    '14:00','14:30','15:00','15:30','16:00','16:30','17:00','17:30',
    '18:00','18:30','19:00','19:30','20:00','20:30','21:00','21:30',
    '22:00','22:30','23:00',
  ];

  @override
  void dispose() {
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      locale: const Locale('ar', 'EG'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final price = _priceCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_priceCtrl.text.trim());

    final ok = await ref.read(createSessionProvider.notifier).create(
      sport: _sport,
      creatorId: user.uid,
      creatorName: user.displayName ?? user.username,
      city: _city,
      location: _locationCtrl.text.trim(),
      date: _date,
      time: _time,
      totalPlayers: _totalPlayers,
      currentPlayers: _currentPlayers,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      pricePerPlayer: price,
    );

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نشر طلب اللاعبين! 🎉')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('طلب لاعبين')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sport selector
            const Text('الرياضة', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: _sports.map((s) {
                final sel = _sport == s.$1;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: s.$1 == _sports.last.$1 ? 0 : 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _sport = s.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel ? AppColors.primary : Theme.of(context).colorScheme.outline),
                        ),
                        child: Text(s.$2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          )),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Location
            const Text('المكان', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                hintText: 'مثال: ملعب النادي الإسماعيلي',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'اكتب المكان' : null,
            ),
            const SizedBox(height: 16),

            // City
            const Text('المدينة', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _city,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.location_city_outlined)),
              items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _city = v!),
            ),
            const SizedBox(height: 16),

            // Date + time row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('التاريخ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textMuted),
                              const SizedBox(width: 8),
                              Text('${_date.day}/${_date.month}/${_date.year}',
                                style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الوقت', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _time,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          prefixIcon: Icon(Icons.access_time_outlined, size: 18),
                        ),
                        items: _times.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setState(() => _time = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Players needed
            const Text('عدد اللاعبين', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Column(
                children: [
                  _PlayerRow(
                    label: 'إجمالي اللاعبين',
                    value: _totalPlayers,
                    min: 2, max: 22,
                    onDec: () => setState(() { if (_totalPlayers > 2) { _totalPlayers--; if (_currentPlayers > _totalPlayers) _currentPlayers = _totalPlayers - 1; } }),
                    onInc: () => setState(() { if (_totalPlayers < 22) _totalPlayers++; }),
                  ),
                  const Divider(height: 20),
                  _PlayerRow(
                    label: 'عندك كام لاعب',
                    value: _currentPlayers,
                    min: 1, max: _totalPlayers - 1,
                    onDec: () => setState(() { if (_currentPlayers > 1) _currentPlayers--; }),
                    onInc: () => setState(() { if (_currentPlayers < _totalPlayers - 1) _currentPlayers++; }),
                  ),
                  const SizedBox(height: 4),
                  Text('محتاج ${_totalPlayers - _currentPlayers} لاعبين',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Price per player (optional)
            const Text('السعر للاعب (اختياري)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'بالجنيه، اتركه فاضي لو مجاني',
                prefixIcon: Icon(Icons.payments_outlined),
                suffixText: 'ج',
              ),
            ),
            const SizedBox(height: 16),

            // Description (optional)
            const Text('ملاحظات (اختياري)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'أي تفاصيل إضافية عن الماتش...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: state.isLoading ? null : _submit,
              child: state.isLoading
                  ? const SizedBox(height: 22, width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('انشر الطلب'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final String label;
  final int value, min, max;
  final VoidCallback onDec, onInc;
  const _PlayerRow({
    required this.label, required this.value,
    required this.min, required this.max,
    required this.onDec, required this.onInc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ),
        GestureDetector(
          onTap: onDec,
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: value <= min ? Colors.grey.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.remove, size: 16,
              color: value <= min ? AppColors.textMuted : AppColors.primary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('$value',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        GestureDetector(
          onTap: onInc,
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: value >= max ? Colors.grey.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.add, size: 16,
              color: value >= max ? AppColors.textMuted : AppColors.primary),
          ),
        ),
      ],
    );
  }
}
