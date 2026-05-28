import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

// ── Model ─────────────────────────────────────────────────────────────────

class AdEntity {
  final String id;
  final String title;
  final String body;
  final bool isActive;
  final int order;
  final DateTime createdAt;

  const AdEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.isActive,
    required this.order,
    required this.createdAt,
  });

  factory AdEntity.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AdEntity(
      id: doc.id,
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      isActive: d['isActive'] as bool? ?? true,
      order: d['order'] as int? ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'isActive': isActive,
        'order': order,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

// ── Provider ──────────────────────────────────────────────────────────────

final adsStreamProvider = StreamProvider<List<AdEntity>>((ref) {
  return FirebaseFirestore.instance
      .collection(AppConstants.adsCollection)
      .orderBy('order')
      .snapshots()
      .map((snap) => snap.docs.map(AdEntity.fromFirestore).toList());
});

// ── Screen ────────────────────────────────────────────────────────────────

class AdminAdsScreen extends ConsumerWidget {
  const AdminAdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(adsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعلانات')),
      body: adsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (ads) => ads.isEmpty
            ? const Center(
                child: Text('لا توجد إعلانات بعد',
                    style: TextStyle(color: AppColors.textMuted)))
            : ListView.separated(
                padding:
                    const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: ads.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (ctx, i) => _AdTile(ad: ads[i])
                    .animate(delay: (i * 50).ms)
                    .fadeIn()
                    .slideX(begin: 0.04),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة إعلان',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final orderCtrl = TextEditingController(text: '0');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة إعلان جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'النص',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: orderCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الترتيب (رقم)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إضافة')),
        ],
      ),
    );

    if (confirmed != true) return;
    final title = titleCtrl.text.trim();
    final body = bodyCtrl.text.trim();
    if (title.isEmpty) return;

    await FirebaseFirestore.instance
        .collection(AppConstants.adsCollection)
        .add({
      'title': title,
      'body': body,
      'isActive': true,
      'order': int.tryParse(orderCtrl.text.trim()) ?? 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

// ── Ad tile ───────────────────────────────────────────────────────────────

class _AdTile extends StatelessWidget {
  final AdEntity ad;
  const _AdTile({required this.ad});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ad.isActive
              ? AppColors.primary.withValues(alpha: 0.4)
              : Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.campaign_rounded,
                color: Color(0xFF7C4DFF), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ad.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                if (ad.body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(ad.body,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              // Toggle active
              Switch(
                value: ad.isActive,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  FirebaseFirestore.instance
                      .collection(AppConstants.adsCollection)
                      .doc(ad.id)
                      .update({'isActive': val});
                },
              ),
              // Delete
              GestureDetector(
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('حذف الإعلان؟'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('إلغاء')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('حذف',
                              style:
                                  TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                  if (ok != true) return;
                  await FirebaseFirestore.instance
                      .collection(AppConstants.adsCollection)
                      .doc(ad.id)
                      .delete();
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline_rounded,
                      color: AppColors.error, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
