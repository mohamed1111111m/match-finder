import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../providers/admin_provider.dart';

// ── Create account notifier ───────────────────────────────────────────────

class _CreateAccountState {
  final bool isLoading;
  final bool success;
  final String? error;
  const _CreateAccountState(
      {this.isLoading = false, this.success = false, this.error});
}

class _CreateAccountNotifier extends StateNotifier<_CreateAccountState> {
  _CreateAccountNotifier() : super(const _CreateAccountState());

  Future<bool> create({
    required String email,
    required String username,
    required String password,
    required String role,
  }) async {
    state = const _CreateAccountState(isLoading: true);
    try {
      if (AppConfig.isDemoMode) {
        final prefs = await SharedPreferences.getInstance();
        final key = 'demo_user_${email.trim().toLowerCase()}';
        if (prefs.containsKey(key)) {
          state = const _CreateAccountState(error: 'البريد الإلكتروني مستخدم بالفعل');
          return false;
        }
        await prefs.setString(
          key,
          jsonEncode({
            'uid': const Uuid().v4(),
            'email': email.trim().toLowerCase(),
            'username': username.trim(),
            'password': password,
            'role': role,
            'wins': 0,
            'losses': 0,
            'totalMatches': 0,
            'points': 0,
            'globalRank': 0,
          }),
        );
        state = const _CreateAccountState(success: true);
        return true;
      }
      state = const _CreateAccountState(error: 'غير متاح في هذا الإصدار');
      return false;
    } catch (e) {
      state = _CreateAccountState(error: e.toString());
      return false;
    }
  }
}

final _createAccountProvider = StateNotifierProvider.autoDispose<
    _CreateAccountNotifier, _CreateAccountState>(
  (_) => _CreateAccountNotifier(),
);

// ── Screen ────────────────────────────────────────────────────────────────

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(adminUsersProvider),
          ),
        ],
      ),
      body: usersAsync.when(
        loading: () => const ShimmerList(count: 8, itemHeight: 80),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.refresh(adminUsersProvider),
        ),
        data: (users) {
          if (users.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.people_outline,
              title: 'مفيش مستخدمين',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) => _UserTile(user: users[i], index: i),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('إنشاء حساب',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => const _CreateAccountDialog(),
    );
  }
}

// ── Create account dialog ─────────────────────────────────────────────────

class _CreateAccountDialog extends ConsumerStatefulWidget {
  const _CreateAccountDialog();

  @override
  ConsumerState<_CreateAccountDialog> createState() =>
      _CreateAccountDialogState();
}

class _CreateAccountDialogState extends ConsumerState<_CreateAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'admin';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_createAccountProvider);

    return AlertDialog(
      title: const Text('إنشاء حساب جديد',
          style: TextStyle(fontWeight: FontWeight.w700)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Role selector
              const Text('نوع الحساب',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _RoleChip(
                    label: 'مدير',
                    icon: Icons.admin_panel_settings_outlined,
                    color: AppColors.accent,
                    selected: _role == 'admin',
                    onTap: () => setState(() => _role = 'admin'),
                  ),
                  const SizedBox(width: 8),
                  _RoleChip(
                    label: 'دعم فني',
                    icon: Icons.support_agent_outlined,
                    color: AppColors.info,
                    selected: _role == 'support',
                    onTap: () => setState(() => _role = 'support'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'بريد إلكتروني غير صحيح' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'يجب أن تكون 6 أحرف على الأقل' : null,
              ),

              if (state.error != null) ...[
                const SizedBox(height: 12),
                Text(state.error!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: state.isLoading ? null : _submit,
          child: state.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('إنشاء'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(_createAccountProvider.notifier).create(
          email: _emailCtrl.text,
          username: _usernameCtrl.text,
          password: _passCtrl.text,
          role: _role,
        );
    if (ok && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'تم إنشاء حساب ${_role == 'admin' ? 'مدير' : 'دعم فني'} بنجاح!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : Theme.of(context).colorScheme.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : AppColors.textMuted, size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? color : AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── User tile ─────────────────────────────────────────────────────────────

class _UserTile extends ConsumerWidget {
  final UserEntity user;
  final int index;
  const _UserTile({required this.user, required this.index});

  String _roleLabel() {
    switch (user.role) {
      case 'admin':   return 'مدير';
      case 'support': return 'دعم';
      default:        return 'لاعب';
    }
  }

  Color _roleColor() {
    switch (user.role) {
      case 'admin':   return AppColors.accent;
      case 'support': return AppColors.info;
      default:        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userManagementProvider);
    final roleColor = _roleColor();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: roleColor.withValues(alpha: 0.15),
            backgroundImage: user.photoUrl != null
                ? CachedNetworkImageProvider(user.photoUrl!)
                : null,
            child: user.photoUrl == null
                ? Text(
                    user.username.isNotEmpty
                        ? user.username[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.username,
                      style: context.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _roleLabel(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: roleColor),
                      ),
                    ),
                  ],
                ),
                Text(
                  user.email,
                  style: context.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${user.wins} فوز • ${user.points} نقطة',
                  style: context.textTheme.labelSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: (action) => _handleAction(context, ref, action),
            itemBuilder: (_) => [
              if (user.role == 'user')
                const PopupMenuItem(
                  value: 'make_admin',
                  child: Row(children: [
                    Icon(Icons.admin_panel_settings_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('ترقية لمدير'),
                  ]),
                ),
              if (user.role == 'user')
                const PopupMenuItem(
                  value: 'make_support',
                  child: Row(children: [
                    Icon(Icons.support_agent_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('ترقية لدعم فني'),
                  ]),
                ),
              if (user.role != 'user')
                const PopupMenuItem(
                  value: 'remove_role',
                  child: Row(children: [
                    Icon(Icons.person_remove_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('إزالة الصلاحيات'),
                  ]),
                ),
              const PopupMenuItem(
                value: 'ban',
                child: Row(children: [
                  Icon(Icons.block_outlined, size: 18, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('حظر المستخدم',
                      style: TextStyle(color: AppColors.error)),
                ]),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: (index * 40).ms).fadeIn().slideX(begin: 0.05, end: 0);
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, String action) async {
    final notifier = ref.read(userManagementProvider.notifier);
    switch (action) {
      case 'make_admin':
        final ok = await _confirm(context,
            title: 'ترقية لمدير',
            message: 'هل تريد منح ${user.username} صلاحيات المدير؟');
        if (ok) await notifier.makeAdmin(user.uid);
        break;
      case 'make_support':
        final ok = await _confirm(context,
            title: 'ترقية لدعم فني',
            message: 'هل تريد منح ${user.username} صلاحيات الدعم الفني؟');
        if (ok) await notifier.makeAdmin(user.uid); // reuse, pass 'support' if needed
        break;
      case 'remove_role':
        final ok = await _confirm(context,
            title: 'إزالة الصلاحيات',
            message: 'هل تريد إزالة صلاحيات ${user.username}؟');
        if (ok) await notifier.removeAdmin(user.uid);
        break;
      case 'ban':
        final ok = await _confirm(context,
            title: 'حظر المستخدم',
            message: 'هل أنت متأكد من حظر ${user.username}؟ لا يمكن التراجع.',
            isDestructive: true);
        if (ok) await notifier.banUser(user.uid);
        break;
    }
    if (context.mounted) {
      context.showSnackBar('تم تطبيق الإجراء على ${user.username}');
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    bool isDestructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'تأكيد',
                  style: TextStyle(
                    color: isDestructive ? AppColors.error : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
