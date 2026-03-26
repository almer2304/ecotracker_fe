import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/collector_provider.dart';
import '../../pickup/models/pickup_model.dart';
import 'complete_task_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

/// Halaman khusus yang muncul setelah collector menekan "Terima"
/// Menampilkan detail pickup + embedded Google Maps
class ActivePickupScreen extends StatefulWidget {
  final PickupModel pickup;

  const ActivePickupScreen({super.key, required this.pickup});

  @override
  State<ActivePickupScreen> createState() => _ActivePickupScreenState();
}

class _ActivePickupScreenState extends State<ActivePickupScreen> {
  late PickupModel _pickup;
  bool _isActing = false;

  @override
  void initState() {
    super.initState();
    _pickup = widget.pickup;
  }

  Future<void> _refresh() async {
    await context.read<CollectorProvider>().loadAssignedPickup();
    final updated = context.read<CollectorProvider>().assignedPickup;
    if (updated != null && mounted) {
      setState(() => _pickup = updated);
    }
  }

  Future<void> _handleAction() async {
    setState(() => _isActing = true);
    final provider = context.read<CollectorProvider>();

    try {
      switch (_pickup.status) {
        case 'accepted':
          await provider.startPickup(_pickup.id);
          break;
        case 'in_progress':
          await provider.arriveAtPickup(_pickup.id);
          break;
        case 'arrived':
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (_) => CompleteTaskScreen(pickupId: _pickup.id),
            ));
          }
          return;
      }
      await _refresh();
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _openGoogleMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${_pickup.lat},${_pickup.lon}&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  String _getActionLabel() {
    switch (_pickup.status) {
      case 'accepted': return 'Mulai Berangkat';
      case 'in_progress': return 'Saya Sudah Tiba';
      case 'arrived': return 'Selesaikan Pickup';
      default: return 'Proses';
    }
  }

  IconData _getActionIcon() {
    switch (_pickup.status) {
      case 'accepted': return Icons.directions_car_rounded;
      case 'in_progress': return Icons.location_on_rounded;
      case 'arrived': return Icons.done_all_rounded;
      default: return Icons.arrow_forward;
    }
  }

  Color _getStatusColor() {
    switch (_pickup.status) {
      case 'accepted': return AppColors.info;
      case 'in_progress': return AppColors.warning;
      case 'arrived': return AppColors.success;
      default: return AppColors.collectorPrimary;
    }
  }

  String _getStatusDescription() {
    switch (_pickup.status) {
      case 'accepted': return 'Pickup diterima. Silakan berangkat ke lokasi user.';
      case 'in_progress': return 'Kamu sedang dalam perjalanan menuju lokasi user.';
      case 'arrived': return 'Kamu sudah tiba! Selesaikan pickup dengan memasukkan data sampah.';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.collectorPrimary,
        foregroundColor: Colors.white,
        title: const Text('Pickup Aktif'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Status Banner ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: _getStatusColor().withOpacity(0.1),
              child: Row(children: [
                Icon(Icons.info_rounded, color: _getStatusColor(), size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  _getStatusDescription(),
                  style: AppTextStyles.bodySmall.copyWith(color: _getStatusColor(), fontWeight: FontWeight.w600),
                )),
                StatusBadge(status: _pickup.status),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Info User ─────────────────────────────────────────────
                _SectionCard(
                  title: 'Informasi User',
                  icon: Icons.person_rounded,
                  child: Column(children: [
                    if (_pickup.user != null) ...[
                      _InfoRow(Icons.person_outline, 'Nama', _pickup.user!.name),
                      if (_pickup.user!.phone != null)
                        _InfoRow(Icons.phone_rounded, 'Telepon', _pickup.user!.phone!),
                    ],
                    _InfoRow(Icons.location_on_rounded, 'Alamat', _pickup.address),
                    if (_pickup.notes != null && _pickup.notes!.isNotEmpty)
                      _InfoRow(Icons.notes_rounded, 'Catatan', _pickup.notes!),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── Lokasi Pickup ─────────────────────────────────────────
                _SectionCard(
                  title: 'Lokasi Pickup',
                  icon: Icons.map_rounded,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openGoogleMaps,
                      icon: const Icon(Icons.map_rounded, size: 20),
                      label: const Text('Buka di Google Maps'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.collectorPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Foto Sampah ───────────────────────────────────────────
                if (_pickup.photoUrl != null) ...[
                  _SectionCard(
                    title: 'Foto Sampah',
                    icon: Icons.photo_rounded,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _pickup.photoUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Tombol Aksi ───────────────────────────────────────────
                if (_pickup.status != 'arrived')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isActing ? null : _handleAction,
                      icon: _isActing
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(_getActionIcon()),
                      label: Text(_getActionLabel()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.collectorPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isActing ? null : _handleAction,
                      icon: _isActing
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.done_all_rounded),
                      label: const Text('Selesaikan Pickup'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

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
            Icon(icon, size: 18, color: AppColors.collectorPrimary),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.h4.copyWith(color: AppColors.collectorPrimary)),
          ]),
        ),
        const Divider(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: child,
        ),
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