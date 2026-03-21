import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/collector_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'complete_task_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class CollectorHomeScreen extends StatefulWidget {
  const CollectorHomeScreen({super.key});

  @override
  State<CollectorHomeScreen> createState() => _CollectorHomeScreenState();
}

class _CollectorHomeScreenState extends State<CollectorHomeScreen> {
  Timer? _refreshTimer;
  Timer? _locationTimer;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      _isOnline = auth.user?.isOnline ?? false;
      context.read<CollectorProvider>().loadAssignedPickup();
      _startRefreshTimer();
      _startLocationUpdates();
    });
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) context.read<CollectorProvider>().loadAssignedPickup();
    });
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition();
        if (mounted) context.read<CollectorProvider>().updateLocation(pos.latitude, pos.longitude);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleOnline() async {
    final newStatus = !_isOnline;
    final success = await context.read<CollectorProvider>().updateStatus(newStatus);
    if (success) {
      setState(() => _isOnline = newStatus);
      await context.read<AuthProvider>().refreshProfile();
      if (newStatus) {
        try {
          final pos = await Geolocator.getCurrentPosition();
          context.read<CollectorProvider>().updateLocation(pos.latitude, pos.longitude);
        } catch (_) {}
      }
    }
  }

  Future<void> _openMaps(double lat, double lon) async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.collectorPrimary,
        onRefresh: () => context.read<CollectorProvider>().loadAssignedPickup(),
        child: CustomScrollView(slivers: [
          // AppBar with online toggle
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.collectorPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.collectorGradient),
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Consumer<AuthProvider>(
                    builder: (_, auth, __) => Row(children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: Text((auth.user?.name ?? 'C')[0], style: AppTextStyles.h4.copyWith(color: Colors.white)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(auth.user?.name ?? '', style: AppTextStyles.h4.copyWith(color: Colors.white)),
                        Row(children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text('${auth.user?.averageRating.toStringAsFixed(1) ?? 0}',
                              style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                        ]),
                      ])),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Colors.white),
                        onPressed: () async {
                          await context.read<AuthProvider>().logout();
                          if (mounted) Navigator.pushReplacementNamed(context, '/login');
                        },
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  // Online toggle
                  GestureDetector(
                    onTap: _toggleOnline,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _isOnline ? Colors.white : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(
                          color: _isOnline ? AppColors.success : Colors.grey,
                          shape: BoxShape.circle,
                        )),
                        const SizedBox(width: 8),
                        Text(
                          _isOnline ? '🟢 ONLINE - Siap Menerima Pickup' : '⚫ OFFLINE',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _isOnline ? AppColors.success : Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.toggle_on_rounded,
                            color: _isOnline ? AppColors.success : Colors.white54, size: 28),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // Stats
                Consumer<AuthProvider>(
                  builder: (_, auth, __) => Row(children: [
                    Expanded(child: StatCard(label: 'Total Pickup', value: '${auth.user?.totalPickupsCompleted ?? 0}', icon: Icons.recycling, color: AppColors.collectorPrimary)),
                    const SizedBox(width: 12),
                    Expanded(child: StatCard(label: 'Berat (kg)', value: '${auth.user?.totalWeightCollected.toStringAsFixed(1) ?? 0}', icon: Icons.scale, color: AppColors.warning)),
                    const SizedBox(width: 12),
                    Expanded(child: StatCard(label: 'Rating', value: '${auth.user?.averageRating.toStringAsFixed(1) ?? 0}', icon: Icons.star, color: Colors.amber)),
                  ]),
                ),
                const SizedBox(height: 20),

                // Active pickup card
                Consumer<CollectorProvider>(
                  builder: (_, provider, __) {
                    if (provider.isLoading) return const ShimmerCard(height: 180);

                    final pickup = provider.assignedPickup;
                    if (pickup == null) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(children: [
                          const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textHint),
                          const SizedBox(height: 12),
                          Text('Tidak ada pickup aktif', style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(_isOnline ? 'Tunggu assignment dari sistem...' : 'Set status ONLINE untuk menerima pickup',
                              style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
                        ]),
                      );
                    }

                    return _ActivePickupCard(
                      pickup: pickup,
                      onNavigate: () => _openMaps(pickup.lat, pickup.lon),
                      onAction: () => _handlePickupAction(pickup),
                    );
                  },
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _handlePickupAction(dynamic pickup) async {
    final provider = context.read<CollectorProvider>();
    switch (pickup.status) {
      case 'assigned':
      case 'reassigned':
        await provider.acceptPickup(pickup.id);
        break;
      case 'accepted':
        await provider.startPickup(pickup.id);
        break;
      case 'in_progress':
        await provider.arriveAtPickup(pickup.id);
        break;
      case 'arrived':
        if (mounted) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => CompleteTaskScreen(pickupId: pickup.id),
          ));
        }
        break;
    }
  }
}

class _ActivePickupCard extends StatelessWidget {
  final dynamic pickup;
  final VoidCallback onNavigate;
  final VoidCallback onAction;

  const _ActivePickupCard({required this.pickup, required this.onNavigate, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.collectorPrimary.withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: AppColors.collectorPrimary.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.collectorPrimary.withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            const Icon(Icons.assignment_rounded, color: AppColors.collectorPrimary, size: 20),
            const SizedBox(width: 8),
            Text('Pickup Aktif', style: AppTextStyles.h4.copyWith(color: AppColors.collectorPrimary)),
            const Spacer(),
            StatusBadge(status: pickup.status),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Address
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.location_on_rounded, color: AppColors.error, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(pickup.address, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 8),

            // User info
            if (pickup.user != null)
              Row(children: [
                const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(pickup.user.name, style: AppTextStyles.bodySmall),
                if (pickup.user.phone != null) ...[
                  const SizedBox(width: 8),
                  Text('• ${pickup.user.phone}', style: AppTextStyles.bodySmall),
                ],
              ]),

            // Photo preview
            if (pickup.photoUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(pickup.photoUrl, height: 100, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            ],

            const SizedBox(height: 16),

            // Buttons
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: onNavigate,
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('Navigasi'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.collectorPrimary,
                  side: const BorderSide(color: AppColors.collectorPrimary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                onPressed: onAction,
                icon: Icon(_getActionIcon(pickup.status), size: 18),
                label: Text(_getActionLabel(pickup.status)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.collectorPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )),
            ]),
          ]),
        ),
      ]),
    );
  }

  String _getActionLabel(String status) {
    switch (status) {
      case 'assigned': case 'reassigned': return 'Terima';
      case 'accepted': return 'Mulai';
      case 'in_progress': return 'Tiba';
      case 'arrived': return 'Selesaikan';
      default: return 'Proses';
    }
  }

  IconData _getActionIcon(String status) {
    switch (status) {
      case 'assigned': case 'reassigned': return Icons.check_circle_outline;
      case 'accepted': return Icons.directions_car_rounded;
      case 'in_progress': return Icons.location_on_rounded;
      case 'arrived': return Icons.done_all_rounded;
      default: return Icons.arrow_forward;
    }
  }
}
