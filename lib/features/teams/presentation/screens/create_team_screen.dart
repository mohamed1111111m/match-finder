import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/team_provider.dart';

class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _sport = 'football';
  String _city  = 'الإسماعيلية';
  int    _size  = 11;

  static const _sports = [
    ('football',   '⚽ كورة قدم', 11),
    ('padel',      '🎾 بادل',     4),
    ('basketball', '🏀 سلة',      5),
  ];

  static const _cities = ['الإسماعيلية','بورسعيد','السويس','القنطرة','القاهرة','الإسكندرية','المنصورة','طنطا'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final ok = await ref.read(createTeamProvider.notifier).create(
      name: _nameCtrl.text.trim(),
      sport: _sport,
      captainId: user.uid,
      captainName: user.displayName ?? user.username,
      teamSize: _size,
      city: _city,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    );

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إنشاء فريق ${_nameCtrl.text.trim()}! 🎉')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createTeamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء فريق')),
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
                      onTap: () => setState(() {
                        _sport = s.$1;
                        _size  = s.$3;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.secondary
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel ? AppColors.secondary
                                : Theme.of(context).colorScheme.outline),
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

            // Team name
            const Text('اسم الفريق', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'مثال: نجوم المعادي',
                prefixIcon: Icon(Icons.shield_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'اكتب اسم الفريق';
                if (v.trim().length < 3) return 'الاسم قصير جداً';
                return null;
              },
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

            // Team size
            const Text('حجم الفريق', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Row(
                children: [
                  const Text('عدد اللاعبين',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  const Spacer(),
                  _CountBtn(
                    icon: Icons.remove,
                    onTap: () { if (_size > 2) setState(() => _size--); },
                    enabled: _size > 2,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('$_size',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                  _CountBtn(
                    icon: Icons.add,
                    onTap: () { if (_size < 22) setState(() => _size++); },
                    enabled: _size < 22,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text('الافتراضي: ${_sports.firstWhere((s) => s.$1 == _sport).$3} لاعبين',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ),
            const SizedBox(height: 16),

            // Description
            const Text('وصف الفريق (اختياري)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'عرّف بفريقك، أهدافه، مستوى اللاعبين...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // Info box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.secondary, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'هتبقى قائد الفريق تلقائياً وتقدر تدعو لاعبين من بعد كده.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: state.isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              child: state.isLoading
                  ? const SizedBox(height: 22, width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('إنشاء الفريق'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CountBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _CountBtn({required this.icon, required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.secondary.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18,
          color: enabled ? AppColors.secondary : AppColors.textMuted),
      ),
    );
  }
}
