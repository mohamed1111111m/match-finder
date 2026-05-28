import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tournaments/domain/entities/tournament_entity.dart';
import '../providers/admin_provider.dart';

class CreateTournamentScreen extends ConsumerStatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  ConsumerState<CreateTournamentScreen> createState() =>
      _CreateTournamentScreenState();
}

class _CreateTournamentScreenState
    extends ConsumerState<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _entryFeeCtrl = TextEditingController(text: '0');
  final _prizepoolCtrl = TextEditingController(text: '0');
  final _maxParticipantsCtrl = TextEditingController(text: '16');

  String _selectedGame = 'FIFA';
  String _selectedFormat = '1v1';
  DateTime _startDate = DateTime.now().add(const Duration(days: 3));
  DateTime _endDate = DateTime.now().add(const Duration(days: 4));

  final _games = [
    'FIFA', 'PUBG Mobile', 'Free Fire', 'Valorant', 'CS2',
    'Fortnite', 'Rocket League', 'eFootball', 'Other'
  ];

  final _formats = ['1v1', '2v2', '5v5', 'Squad (4)', 'Battle Royale', 'Round Robin'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _entryFeeCtrl.dispose();
    _prizepoolCtrl.dispose();
    _maxParticipantsCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final tournament = TournamentEntity(
      id: const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      game: _selectedGame,
      format: _selectedFormat,
      status: 'upcoming',
      entryFee: double.tryParse(_entryFeeCtrl.text) ?? 0,
      prizePool: double.tryParse(_prizepoolCtrl.text) ?? 0,
      maxParticipants: int.tryParse(_maxParticipantsCtrl.text) ?? 16,
      currentParticipants: 0,
      startDate: _startDate,
      endDate: _endDate,
      createdBy: user.uid,
      participantIds: const [],
      pendingApprovalIds: const [],
      createdAt: DateTime.now(),
    );

    final success =
        await ref.read(createTournamentProvider.notifier).create(tournament);

    if (success && mounted) {
      context.showSnackBar('Tournament created successfully!');
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDateTimePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createTournamentProvider);

    ref.listen(createTournamentProvider, (_, next) {
      if (next.error != null) {
        context.showSnackBar(next.error!, isError: true);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Create Tournament')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(context, 'Basic Info'),
              const SizedBox(height: 12),

              // Title
              TextFormField(
                controller: _titleCtrl,
                validator: (v) => AppValidators.required(v, 'Title'),
                decoration: const InputDecoration(
                  labelText: 'Tournament Title',
                  prefixIcon: Icon(Icons.emoji_events_outlined),
                ),
              ),
              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                validator: (v) => AppValidators.required(v, 'Description'),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),

              // Game
              DropdownButtonFormField<String>(
                value: _selectedGame,
                decoration: const InputDecoration(
                  labelText: 'Game',
                  prefixIcon: Icon(Icons.sports_esports_outlined),
                ),
                items: _games
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedGame = v!),
              ),
              const SizedBox(height: 14),

              // Format
              DropdownButtonFormField<String>(
                value: _selectedFormat,
                decoration: const InputDecoration(
                  labelText: 'Format',
                  prefixIcon: Icon(Icons.group_outlined),
                ),
                items: _formats
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedFormat = v!),
              ),

              const SizedBox(height: 24),
              _sectionTitle(context, 'Financial'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _entryFeeCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) => AppValidators.positiveNumber(v, 'Entry Fee'),
                      decoration: const InputDecoration(
                        labelText: 'Entry Fee',
                        suffixText: 'EGP',
                        prefixIcon: Icon(Icons.payment_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _prizepoolCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) => AppValidators.positiveNumber(v, 'Prize Pool'),
                      decoration: const InputDecoration(
                        labelText: 'Prize Pool',
                        suffixText: 'EGP',
                        prefixIcon: Icon(Icons.emoji_events_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _maxParticipantsCtrl,
                keyboardType: TextInputType.number,
                validator: AppValidators.minParticipants,
                decoration: const InputDecoration(
                  labelText: 'Max Participants',
                  prefixIcon: Icon(Icons.people_outline),
                ),
              ),

              const SizedBox(height: 24),
              _sectionTitle(context, 'Schedule'),
              const SizedBox(height: 12),

              // Start date
              _DatePickerTile(
                label: 'Start Date & Time',
                date: _startDate,
                onTap: () => _pickDate(isStart: true),
              ),
              const SizedBox(height: 10),

              // End date
              _DatePickerTile(
                label: 'End Date & Time',
                date: _endDate,
                onTap: () => _pickDate(isStart: false),
              ),

              const SizedBox(height: 32),

              AppButton(
                label: 'Create Tournament',
                onPressed: createState.isLoading ? null : _create,
                isLoading: createState.isLoading,
                icon: Icons.add_circle_outline,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: context.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700, color: AppColors.primary),
    );
  }
}

// ─── Date picker tile ──────────────────────────────────────────────────────

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerTile(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.textSecondary)),
                Text(
                  date.formattedDateTime,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.edit_calendar_outlined,
                size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ─── DateTime picker helper ────────────────────────────────────────────────

Future<DateTime?> showDateTimePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initialDate),
  );
  if (time == null) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
