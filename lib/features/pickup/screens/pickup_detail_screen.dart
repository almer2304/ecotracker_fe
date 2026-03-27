import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/pickup_model.dart';
import '../providers/pickup_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class PickupDetailScreen extends StatefulWidget {
  final PickupModel pickup;
  const PickupDetailScreen({super.key, required this.pickup});

  @override
  State<PickupDetailScreen> createState() => _PickupDetailScreenState();
}

class _PickupDetailScreenState extends State<PickupDetailScreen> {
  bool _hasRated = false;
  bool _isSubmittingRating = false;

  Future<void> _openMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${widget.pickup.lat},${widget.pickup.lon}',
    );
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _showRatingDialog() {
    if (widget.pickup.collector == null) return;
    showDialog(
      context: context,
      builder: (_) => _RatingDialog(
        pickupId: widget.pickup.id,
        collectorName: widget.pickup.collector!.name,
        onSubmitted: () => setState(() => _hasRated = true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pickup = widget.pickup;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Pickup'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Status Banner ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _statusColor(pickup.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _statusColor(pickup.status).withOpacity(0.3)),
            ),
            child: Row(children: [
              Icon(_statusIcon(pickup.status), color: _statusColor(pickup.status), size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(_statusLabel(pickup.status),
                  style: AppTextStyles.bodySmall.copyWith(
                      color: _statusColor(pickup.status), fontWeight: FontWeight.w600))),
              StatusBadge(status: pickup.status),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Info Pickup ────────────────────────────────────────────
          _SectionCard(
            title: 'Informasi Pickup',
            icon: Icons.recycling_rounded,
            child: Column(children: [
              _InfoRow(Icons.location_on_rounded, 'Alamat', pickup.address),
              _InfoRow(Icons.calendar_today_rounded, 'Dibuat',
                  DateFormat('dd MMM yyyy, HH:mm').format(pickup.createdAt.toLocal())),
              if (pickup.completedAt != null)
                _InfoRow(Icons.check_circle_rounded, 'Selesai',
                    DateFormat('dd MMM yyyy, HH:mm').format(pickup.completedAt!.toLocal())),
              if (pickup.notes != null && pickup.notes!.isNotEmpty)
                _InfoRow(Icons.notes_rounded, 'Catatan', pickup.notes!),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Foto Sampah ────────────────────────────────────────────
          if (pickup.photoUrl != null)
            _SectionCard(
              title: 'Foto Sampah',
              icon: Icons.photo_rounded,
              child: Column(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(pickup.photoUrl!,
                      width: double.infinity, height: 200, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox()),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openMaps,
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: const Text('Lihat Lokasi di Maps'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ]),
            ),
          if (pickup.photoUrl == null)
            _SectionCard(
              title: 'Lokasi',
              icon: Icons.map_rounded,
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openMaps,
                  icon: const Icon(Icons.map_rounded, size: 18),
                  label: const Text('Lihat Lokasi di Maps'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),

          // ── Hasil Pickup (jika completed) ──────────────────────────
          if (pickup.isCompleted) ...[
            _SectionCard(
              title: 'Hasil Pickup',
              icon: Icons.assignment_turned_in_rounded,
              child: Column(children: [
                Row(children: [
                  Expanded(child: _StatBox(
                    label: 'Total Berat',
                    value: '${pickup.totalWeight?.toStringAsFixed(2) ?? 0} kg',
                    icon: Icons.scale_rounded,
                    color: AppColors.primary,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _StatBox(
                    label: 'Poin Didapat',
                    value: '+${pickup.totalPointsAwarded ?? 0}',
                    icon: Icons.stars_rounded,
                    color: Colors.amber,
                  )),
                ]),
                if (pickup.items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  ...pickup.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Expanded(child: Text(item.category?.name ?? 'Kategori',
                          style: AppTextStyles.bodySmall)),
                      Text('${item.weightKg.toStringAsFixed(2)} kg',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(width: 12),
                      Text('+${item.pointsAwarded} poin',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.warning, fontWeight: FontWeight.w600)),
                    ]),
                  )),
                ],
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // ── Info Collector ─────────────────────────────────────────
          if (pickup.collector != null)
            _SectionCard(
              title: 'Collector',
              icon: Icons.person_rounded,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.collectorPrimary.withOpacity(0.15),
                    child: Text(pickup.collector!.name[0].toUpperCase(),
                        style: AppTextStyles.h4.copyWith(color: AppColors.collectorPrimary)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(pickup.collector!.name,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    Row(children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(pickup.collector!.averageRating.toStringAsFixed(1),
                          style: AppTextStyles.bodySmall),
                    ]),
                  ])),
                ]),

                // Tombol beri rating (hanya jika pickup completed & belum rating)
                if (pickup.isCompleted && !_hasRated) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showRatingDialog,
                      icon: const Icon(Icons.star_rounded, size: 18),
                      label: const Text('Beri Rating & Ulasan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],

                if (_hasRated) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                      const SizedBox(width: 8),
                      Text('Terima kasih atas ulasanmu!',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.success)),
                    ]),
                  ),
                ],
              ]),
            ),
        ]),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.statusPending;
      case 'assigned': case 'accepted': return AppColors.statusAssigned;
      case 'in_progress': return AppColors.statusInProgress;
      case 'arrived': return AppColors.statusArrived;
      case 'completed': return AppColors.statusCompleted;
      default: return AppColors.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.hourglass_empty_rounded;
      case 'assigned': return Icons.person_pin_rounded;
      case 'accepted': return Icons.check_circle_outline;
      case 'in_progress': return Icons.directions_car_rounded;
      case 'arrived': return Icons.location_on_rounded;
      case 'completed': return Icons.check_circle_rounded;
      default: return Icons.info_outline;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending': return 'Sedang mencari collector terdekat...';
      case 'assigned': return 'Collector ditugaskan, menunggu konfirmasi';
      case 'accepted': return 'Collector sedang bersiap berangkat';
      case 'in_progress': return 'Collector sedang dalam perjalanan menuju lokasimu';
      case 'arrived': return 'Collector sudah tiba di lokasimu!';
      case 'completed': return 'Pickup selesai! Poin telah ditambahkan';
      default: return status;
    }
  }
}

// ── Rating Dialog ──────────────────────────────────────────────────────────

class _RatingDialog extends StatefulWidget {
  final String pickupId;
  final String collectorName;
  final VoidCallback onSubmitted;

  const _RatingDialog({
    required this.pickupId,
    required this.collectorName,
    required this.onSubmitted,
  });

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _rating = 5;
  final _commentCtrl = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _tags = ['Tepat Waktu', 'Ramah', 'Profesional', 'Cepat', 'Rapi'];
  final Set<String> _selectedTags = {};

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final api = ApiClient();
      await api.dio.post(ApiConstants.feedback, data: {
        'feedback_type': 'collector',
        'pickup_id': widget.pickupId,
        'rating': _rating,
        'title': 'Rating dari user',
        'comment': _commentCtrl.text.trim().isEmpty ? 'Tidak ada komentar' : _commentCtrl.text.trim(),
        'tags': _selectedTags.toList(),
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSubmitted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Rating berhasil dikirim!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim rating'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(children: [
        const Icon(Icons.star_rounded, color: Colors.amber, size: 40),
        const SizedBox(height: 8),
        Text('Beri Rating', style: AppTextStyles.h3),
        Text('untuk ${widget.collectorName}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      ]),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Star selector
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) =>
            GestureDetector(
              onTap: () => setState(() => _rating = i + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 40,
                ),
              ),
            ),
          )),
          const SizedBox(height: 6),
          Text(_ratingLabel(_rating),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),

          // Quick tags
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _tags.map((tag) => GestureDetector(
              onTap: () => setState(() {
                if (_selectedTags.contains(tag)) _selectedTags.remove(tag);
                else _selectedTags.add(tag);
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedTags.contains(tag)
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.surfaceVariant,
                  border: Border.all(
                    color: _selectedTags.contains(tag) ? AppColors.primary : AppColors.divider,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(tag, style: AppTextStyles.caption.copyWith(
                  color: _selectedTags.contains(tag) ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: _selectedTags.contains(tag) ? FontWeight.w600 : FontWeight.normal,
                )),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),

          // Comment
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tambahkan komentar (opsional)...',
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Kirim Rating'),
        ),
      ],
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1: return 'Sangat Buruk 😞';
      case 2: return 'Buruk 😕';
      case 3: return 'Cukup 😐';
      case 4: return 'Baik 😊';
      case 5: return 'Sangat Baik! 🤩';
      default: return '';
    }
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
          ]),
        ),
        const Divider(height: 16),
        Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: child),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: AppTextStyles.h3.copyWith(color: color)),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      ]),
    );
  }
}