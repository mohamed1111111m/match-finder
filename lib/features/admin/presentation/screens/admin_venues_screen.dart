import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../venues/domain/entities/venue_entity.dart';
import '../../../venues/presentation/providers/venue_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Every 30-minute slot from 00:00 to 23:30
List<String> _buildSlots({String from = '00:00', String to = '23:30'}) {
  final slots = <String>[];
  var h = int.parse(from.split(':')[0]);
  var m = int.parse(from.split(':')[1]);
  final endH = int.parse(to.split(':')[0]);
  final endM = int.parse(to.split(':')[1]);
  while (h < endH || (h == endH && m <= endM)) {
    slots.add('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
    m += 30;
    if (m >= 60) { m = 0; h++; }
  }
  return slots;
}

String _to12hr(String hhmm) {
  final parts = hhmm.split(':');
  var h = int.parse(parts[0]);
  final m = parts[1];
  final period = h < 12 ? 'AM' : 'PM';
  if (h == 0) {
    h = 12;
  } else if (h > 12) {
    h -= 12;
  }
  return '$h:$m $period';
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminVenuesScreen extends ConsumerWidget {
  const AdminVenuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venues = ref.watch(adminAllVenuesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الملاعب'),
        actions: [
          if (venues.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'حذف كل الملاعب',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('حذف كل الملاعب؟'),
                    content: Text(
                        'سيتم حذف ${venues.length} ملعب بشكل نهائي. هل أنت متأكد؟'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('إلغاء')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('حذف الكل',
                            style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (ok != true) return;
                final notifier =
                    ref.read(adminVenuesNotifierProvider.notifier);
                for (final v in venues) {
                  await notifier.removeVenue(v.id);
                }
              },
            ),
        ],
      ),
      body: venues.isEmpty
          ? const Center(child: Text('مفيش ملاعب', style: TextStyle(color: AppColors.textMuted)))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: venues.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _VenueAdminTile(venue: venues[i])
                  .animate(delay: (i * 40).ms).fadeIn(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة ملعب',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _VenueFormSheet(ref: ref),
    );
  }
}

// ── Venue tile ────────────────────────────────────────────────────────────────

class _VenueAdminTile extends ConsumerStatefulWidget {
  final VenueEntity venue;
  const _VenueAdminTile({required this.venue});

  @override
  ConsumerState<_VenueAdminTile> createState() => _VenueAdminTileState();
}

class _VenueAdminTileState extends ConsumerState<_VenueAdminTile> {
  bool _uploadingPhoto = false;
  String? _deletingPhotoUrl;

  Color _sportColor(String s) {
    switch (s) {
      case 'football':   return AppColors.football;
      case 'padel':      return AppColors.padel;
      case 'basketball': return AppColors.basketball;
      default:           return AppColors.primary;
    }
  }

  IconData _sportIcon(String s) {
    switch (s) {
      case 'football':   return Icons.sports_soccer;
      case 'padel':      return Icons.sports_tennis;
      case 'basketball': return Icons.sports_basketball;
      default:           return Icons.sports;
    }
  }

  Future<void> _quickRemovePhoto(String url) async {
    setState(() => _deletingPhotoUrl = url);
    try {
      final storage = ref.read(storageServiceProvider);
      await storage.deleteFile(url);
      final updated = VenueEntity(
        id: widget.venue.id,
        name: widget.venue.name,
        sport: widget.venue.sport,
        address: widget.venue.address,
        city: widget.venue.city,
        pricePerHour: widget.venue.pricePerHour,
        phone: widget.venue.phone,
        description: widget.venue.description,
        images: widget.venue.images.where((i) => i != url).toList(),
        openTime: widget.venue.openTime,
        closeTime: widget.venue.closeTime,
        isVerified: widget.venue.isVerified,
        rating: widget.venue.rating,
        reviewCount: widget.venue.reviewCount,
        amenities: widget.venue.amenities,
      );
      ref.read(adminVenuesNotifierProvider.notifier).updateVenue(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الصورة ✓')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل حذف الصورة — حاول مرة أخرى')),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingPhotoUrl = null);
    }
  }

  Future<void> _quickAddPhoto() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (xFile == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final storage = ref.read(storageServiceProvider);
      final url = await storage.uploadVenueImage(
          File(xFile.path), widget.venue.id);
      final updated = VenueEntity(
        id: widget.venue.id,
        name: widget.venue.name,
        sport: widget.venue.sport,
        address: widget.venue.address,
        city: widget.venue.city,
        pricePerHour: widget.venue.pricePerHour,
        phone: widget.venue.phone,
        description: widget.venue.description,
        images: [...widget.venue.images, url],
        openTime: widget.venue.openTime,
        closeTime: widget.venue.closeTime,
        isVerified: widget.venue.isVerified,
        rating: widget.venue.rating,
        reviewCount: widget.venue.reviewCount,
        amenities: widget.venue.amenities,
      );
      ref.read(adminVenuesNotifierProvider.notifier).updateVenue(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفع الصورة ✓')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل رفع الصورة — حاول مرة أخرى')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final venue = widget.venue;
    final c = _sportColor(venue.sport);
    final isOpen = ref.watch(venueOpenStatusProvider(venue.id));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(_sportIcon(venue.sport), color: c, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(venue.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                ),
                Text(isOpen ? 'مفتوح' : 'مغلق',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isOpen ? AppColors.success : AppColors.error)),
                const SizedBox(width: 6),
                Switch.adaptive(
                  value: isOpen,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => ref
                      .read(venueOpenStatusProvider(venue.id).notifier)
                      .state = v,
                ),
              ],
            ),
          ),

          // Images row + add button
          SizedBox(
            height: 88,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              children: [
                // Existing images
                ...venue.images.map((url) {
                  final isDeleting = _deletingPhotoUrl == url;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: url.startsWith('http')
                              ? Image.network(url,
                                  width: 80, height: 72, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _photoPlaceholder(c))
                              : Image.file(File(url),
                                  width: 80, height: 72, fit: BoxFit.cover),
                        ),
                        if (isDeleting)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: const ColoredBox(
                                color: Colors.black45,
                                child: Center(
                                  child: SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          Positioned(
                            top: 2, right: 2,
                            child: GestureDetector(
                              onTap: () => _quickRemovePhoto(url),
                              child: Container(
                                decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                // Quick-add photo button
                GestureDetector(
                  onTap: _uploadingPhoto ? null : _quickAddPhoto,
                  child: Container(
                    width: 80,
                    height: 72,
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: c.withValues(alpha: 0.35),
                          style: BorderStyle.solid),
                    ),
                    child: _uploadingPhoto
                        ? Center(
                            child: SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: c, strokeWidth: 2),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded,
                                  color: c, size: 22),
                              const SizedBox(height: 4),
                              Text('إضافة',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: c,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address + price
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(venue.address,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ),
                    Text(venue.priceText,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                // Open/close hours
                Row(
                  children: [
                    const Icon(Icons.access_time_outlined,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('${_to12hr(venue.openTime)} – ${_to12hr(venue.closeTime)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 10),

                // Time slots
                const Text('المواعيد المتاحة',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted)),
                const SizedBox(height: 6),
                _TimeSlotsEditor(
                    venueId: venue.id,
                    openTime: venue.openTime,
                    closeTime: venue.closeTime),

                const SizedBox(height: 10),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showEditSheet(context, venue),
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: const Text('تعديل'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          foregroundColor: AppColors.secondary,
                          side: const BorderSide(color: AppColors.secondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _confirmDelete(context, venue),
                        icon: const Icon(Icons.delete_outline, size: 15),
                        label: const Text('حذف'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder(Color c) => Container(
        width: 80, height: 72,
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.broken_image_outlined, color: c, size: 24),
      );

  void _showEditSheet(BuildContext context, VenueEntity v) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _VenueFormSheet(ref: ref, venue: v),
    );
  }

  void _confirmDelete(BuildContext context, VenueEntity v) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الملعب؟',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('هتحذف "${v.name}" نهائياً.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              ref
                  .read(adminVenuesNotifierProvider.notifier)
                  .removeVenue(v.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

// ── Time slots editor ─────────────────────────────────────────────────────────

class _TimeSlotsEditor extends ConsumerStatefulWidget {
  final String venueId;
  final String openTime;
  final String closeTime;
  const _TimeSlotsEditor(
      {required this.venueId,
      required this.openTime,
      required this.closeTime});

  @override
  ConsumerState<_TimeSlotsEditor> createState() => _TimeSlotsEditorState();
}

class _TimeSlotsEditorState extends ConsumerState<_TimeSlotsEditor> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final blocked = ref.watch(blockedSlotsProvider(widget.venueId));
    final slots = _buildSlots(
        from: widget.openTime, to: widget.closeTime);

    // Show first 10 or all
    final visible = _showAll ? slots : slots.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: visible.map((t) {
            final isBlocked = blocked.contains(t);
            return GestureDetector(
              onTap: () {
                final n = ref
                    .read(blockedSlotsProvider(widget.venueId).notifier);
                if (isBlocked) {
                  n.state = Set.from(n.state)..remove(t);
                } else {
                  n.state = Set.from(n.state)..add(t);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isBlocked
                      ? AppColors.error.withValues(alpha: 0.12)
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                      color: isBlocked
                          ? AppColors.error
                          : AppColors.primary),
                ),
                child: Text(_to12hr(t),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isBlocked
                            ? AppColors.error
                            : AppColors.primary)),
              ),
            );
          }).toList(),
        ),
        if (slots.length > 10) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _showAll = !_showAll),
            child: Text(
              _showAll
                  ? 'عرض أقل ▲'
                  : 'عرض كل المواعيد (${slots.length}) ▼',
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Unified add/edit form sheet ───────────────────────────────────────────────

class _VenueFormSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final VenueEntity? venue; // null = add, non-null = edit
  const _VenueFormSheet({required this.ref, this.venue});

  @override
  ConsumerState<_VenueFormSheet> createState() => _VenueFormSheetState();
}

class _VenueFormSheetState extends ConsumerState<_VenueFormSheet> {
  final _form = GlobalKey<FormState>();
  late final _name  = TextEditingController(text: widget.venue?.name ?? '');
  late final _addr  = TextEditingController(text: widget.venue?.address ?? '');
  late final _phone = TextEditingController(text: widget.venue?.phone ?? '');
  late final _price = TextEditingController(
      text: widget.venue != null
          ? widget.venue!.pricePerHour.toInt().toString()
          : '');
  late final _desc = TextEditingController(text: widget.venue?.description ?? '');

  late String _sport = widget.venue?.sport ?? 'football';
  late String _openTime = widget.venue?.openTime ?? '00:00';
  late String _closeTime = widget.venue?.closeTime ?? '23:30';

  late final List<String> _images = List.from(widget.venue?.images ?? []);
  bool _loading = false;

  bool get _isEdit => widget.venue != null;

  // Generate hour+half-hour options for pickers
  static final _timeOpts = _buildSlots(from: '00:00', to: '23:30');

  @override
  void dispose() {
    _name.dispose(); _addr.dispose(); _phone.dispose();
    _price.dispose(); _desc.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        for (final xf in picked) {
          if (!_images.contains(xf.path)) _images.add(xf.path);
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);

    final venueId = _isEdit ? widget.venue!.id : const Uuid().v4();
    final storage = widget.ref.read(storageServiceProvider);

    // Upload any local file paths to Firebase Storage
    final uploadedImages = <String>[];
    for (final path in _images) {
      if (path.startsWith('http')) {
        uploadedImages.add(path); // already a URL
      } else {
        try {
          final url = await storage.uploadVenueImage(File(path), venueId);
          uploadedImages.add(url);
        } catch (_) {
          // skip failed uploads
        }
      }
    }

    final venue = VenueEntity(
      id: venueId,
      name: _name.text.trim(),
      sport: _sport,
      address: _addr.text.trim(),
      city: 'الإسماعيلية',
      pricePerHour: double.tryParse(_price.text.trim()) ?? 200,
      phone: _phone.text.trim(),
      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      images: uploadedImages,
      openTime: _openTime,
      closeTime: _closeTime,
      isVerified: true,
      rating: widget.venue?.rating ?? 0,
      reviewCount: widget.venue?.reviewCount ?? 0,
      amenities: widget.venue?.amenities ?? const [],
    );

    if (_isEdit) {
      widget.ref.read(adminVenuesNotifierProvider.notifier).updateVenue(venue);
    } else {
      widget.ref.read(adminVenuesNotifierProvider.notifier).addVenue(venue);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(_isEdit ? 'تعديل: ${widget.venue!.name}' : 'إضافة ملعب جديد',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),

              // ── Sport ──────────────────────────────────────────────────────
              _SectionLabel(label: 'نوع الرياضة'),
              Row(
                children: [
                  _SportBtn('football',   '⚽ كورة قدم', _sport,
                      (s) => setState(() => _sport = s)),
                  const SizedBox(width: 8),
                  _SportBtn('padel',      '🎾 بادل', _sport,
                      (s) => setState(() => _sport = s)),
                  const SizedBox(width: 8),
                  _SportBtn('basketball', '🏀 سلة', _sport,
                      (s) => setState(() => _sport = s)),
                ],
              ),
              const SizedBox(height: 14),

              // ── Images ─────────────────────────────────────────────────────
              _SectionLabel(label: 'صور الملعب'),
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        style: BorderStyle.solid),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('اختار صور من الجهاز',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              if (_images.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final path = _images[i];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: path.startsWith('http')
                                ? Image.network(path,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover)
                                : Image.file(File(path),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _images.removeAt(i)),
                              child: Container(
                                decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // ── Name & address ─────────────────────────────────────────────
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                    hintText: 'اسم الملعب *',
                    prefixIcon: Icon(Icons.stadium_outlined)),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addr,
                decoration: const InputDecoration(
                    hintText: 'العنوان *',
                    prefixIcon: Icon(Icons.location_on_outlined)),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 10),

              // ── Price & phone ──────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          hintText: 'السعر/ساعة *',
                          prefixIcon: Icon(Icons.payments_outlined),
                          suffixText: 'ج'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          hintText: 'التليفون',
                          prefixIcon: Icon(Icons.phone_outlined)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Open / Close time ──────────────────────────────────────────
              _SectionLabel(label: 'ساعات العمل'),
              Row(
                children: [
                  Expanded(
                    child: _TimeDropdown(
                      label: 'من',
                      value: _openTime,
                      options: _timeOpts,
                      onChanged: (v) => setState(() => _openTime = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TimeDropdown(
                      label: 'إلى',
                      value: _closeTime,
                      options: _timeOpts,
                      onChanged: (v) => setState(() => _closeTime = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Description ────────────────────────────────────────────────
              TextFormField(
                controller: _desc,
                maxLines: 2,
                decoration: const InputDecoration(
                    hintText: 'وصف الملعب (اختياري)',
                    prefixIcon: Icon(Icons.description_outlined)),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(_isEdit ? 'حفظ التعديلات' : 'إضافة الملعب'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Time dropdown ─────────────────────────────────────────────────────────────

class _TimeDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _TimeDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure value is in options
    final safeValue = options.contains(value) ? value : options.first;
    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.access_time_outlined, size: 18)),
      items: options
          .map((t) => DropdownMenuItem(value: t, child: Text(_to12hr(t))))
          .toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted)),
    );
  }
}

// ── Sport button ──────────────────────────────────────────────────────────────

class _SportBtn extends StatelessWidget {
  final String value, label, current;
  final ValueChanged<String> onTap;
  const _SportBtn(this.value, this.label, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final sel = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel
                ? AppColors.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: sel
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.outline),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: sel
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface)),
        ),
      ),
    );
  }
}
