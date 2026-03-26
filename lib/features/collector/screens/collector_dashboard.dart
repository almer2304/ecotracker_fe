import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/collector_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pickup/network/websocket_service.dart';
import '../../pickup/models/pickup_model.dart';
import 'active_pickup_screen.dart';
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
  StreamSubscription? _wsSubscription;
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
      _connectWebSocket();
    });
  }

  void _connectWebSocket() {
    final ws = context.read<WebSocketService>();
    ws.connect();

    _wsSubscription = ws.onNewPickup.listen((data) {
      debugPrint('[WS] Pickup baru! Refresh...');
      if (mounted) {
        context.read<CollectorProvider>().loadAssignedPickup();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.notifications_active_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('📦 Ada pickup baru untukmu!'),
            ]),
            backgroundColor: AppColors.collectorPrimary,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Lihat',
              textColor: Colors.white,
              onPressed: () {
                final pickup = context.read<CollectorProvider>().assignedPickup;
                if (pickup != null && mounted) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ActivePickupScreen(pickup: pickup),
                  ));
                }
              },
            ),
          ),
        );
      }
    });
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
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
    _wsSubscription?.cancel();
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

  // Burger menu untuk collector
  void _showMenu(BuildContext context) {
    final auth = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.collectorPrimary.withOpacity(0.15),
                child: Text((auth.user?.name ?? 'C')[0].toUpperCase(),
                    style: TextStyle(color: AppColors.collectorPrimary, fontWeight: FontWeight.bold)),
              ),
              title: Text(auth.user?.name ?? '', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(auth.user?.email ?? '', style: AppTextStyles.caption),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded, color: AppColors.collectorPrimary),
              title: const Text('Profil Saya'),
              onTap: () {
                Navigator.pop(context);
                _showProfileDialog(context, auth);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: AppColors.collectorPrimary),
              title: const Text('Tentang EcoTracker'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'EcoTracker',
                  applicationVersion: 'V2.0',
                  children: [const Text('Platform manajemen pengambilan sampah daur ulang. Bersama kita jaga lingkungan 🌿')],
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text('Keluar', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                context.read<WebSocketService>().disconnect();
                await context.read<AuthProvider>().logout();
                if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
              },
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Profil Collector'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _profileRow(Icons.person_rounded, 'Nama', auth.user?.name ?? '-'),
          const SizedBox(height: 12),
          _profileRow(Icons.email_rounded, 'Email', auth.user?.email ?? '-'),
          const SizedBox(height: 12),
          _profileRow(Icons.star_rounded, 'Rating', '${auth.user?.averageRating.toStringAsFixed(1) ?? 0}'),
          const SizedBox(height: 12),
          _profileRow(Icons.recycling_rounded, 'Total Pickup', '${auth.user?.totalPickupsCompleted ?? 0}'),
          const SizedBox(height: 12),
          _profileRow(Icons.scale_rounded, 'Total Berat', '${auth.user?.totalWeightCollected.toStringAsFixed(1) ?? 0} kg'),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.collectorPrimary),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      ]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.collectorPrimary,
        onRefresh: () => context.read<CollectorProvider>().loadAssignedPickup(),
        child: CustomScrollView(slivers: [
          // ── AppBar ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.collectorPrimary,
            actions: [
              // WS indicator
              Consumer<WebSocketService>(
                builder: (_, ws, __) => Padding(
                  padding: const EdgeInsets.only(top: 14, right: 4),
                  child: Tooltip(
                    message: ws.isConnected ? 'Real-time aktif' : 'Real-time tidak aktif',
                    child: Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: ws.isConnected ? Colors.greenAccent : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              // Burger menu
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => _showMenu(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.collectorGradient),
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                  Consumer<AuthProvider>(
                    builder: (_, auth, __) => Row(children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: Text((auth.user?.name ?? 'C')[0],
                            style: AppTextStyles.h4.copyWith(color: Colors.white)),
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
                    Expanded(child: StatCard(label: 'Total Pickup',
                        value: '${auth.user?.totalPickupsCompleted ?? 0}',
                        icon: Icons.recycling, color: AppColors.collectorPrimary)),
                    const SizedBox(width: 12),
                    Expanded(child: StatCard(label: 'Berat (kg)',
                        value: '${auth.user?.totalWeightCollected.toStringAsFixed(1) ?? 0}',
                        icon: Icons.scale, color: AppColors.warning)),
                    const SizedBox(width: 12),
                    Expanded(child: StatCard(label: 'Rating',
                        value: '${auth.user?.averageRating.toStringAsFixed(1) ?? 0}',
                        icon: Icons.star, color: Colors.amber)),
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
                          Text('Tidak ada pickup aktif',
                              style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(
                            _isOnline
                                ? 'Tunggu assignment dari sistem...'
                                : 'Set status ONLINE untuk menerima pickup',
                            style: AppTextStyles.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ]),
                      );
                    }

                    return _AssignedPickupCard(
                      pickup: pickup,
                      onAccept: () => _handleAccept(pickup),
                      onViewDetail: () => _goToActivePickup(pickup),
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

  /// Terima pickup lalu langsung navigasi ke halaman detail
  Future<void> _handleAccept(PickupModel pickup) async {
    final provider = context.read<CollectorProvider>();

    if (pickup.status == 'assigned' || pickup.status == 'reassigned') {
      final success = await provider.acceptPickup(pickup.id);
      if (success && mounted) {
        // Tampilkan notif bahwa pickup diterima
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pickup diterima! Silakan berangkat ke lokasi.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
        // Navigasi ke halaman aktif
        final updated = provider.assignedPickup;
        if (updated != null) _goToActivePickup(updated);
      }
    }
  }

  void _goToActivePickup(PickupModel pickup) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ActivePickupScreen(pickup: pickup),
    )).then((_) {
      // Refresh setelah kembali dari halaman aktif
      context.read<CollectorProvider>().loadAssignedPickup();
    });
  }
}

/// Card pickup yang sudah di-assign, sebelum di-accept
class _AssignedPickupCard extends StatelessWidget {
  final PickupModel pickup;
  final VoidCallback onAccept;
  final VoidCallback onViewDetail;

  const _AssignedPickupCard({
    required this.pickup,
    required this.onAccept,
    required this.onViewDetail,
  });

  bool get _isAccepted => ['accepted', 'in_progress', 'arrived'].contains(pickup.status);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.collectorPrimary.withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(
            color: AppColors.collectorPrimary.withOpacity(0.1),
            blurRadius: 12, offset: const Offset(0, 4))],
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
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.location_on_rounded, color: AppColors.error, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(pickup.address,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600))),
            ]),
            if (pickup.user != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(pickup.user!.name, style: AppTextStyles.bodySmall),
                if (pickup.user!.phone != null) ...[
                  const SizedBox(width: 8),
                  Text('• ${pickup.user!.phone}', style: AppTextStyles.bodySmall),
                ],
              ]),
            ],
            const SizedBox(height: 16),

            // Tombol: kalau sudah accepted → "Lihat Detail", kalau belum → "Terima"
            if (_isAccepted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onViewDetail,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Lihat Detail & Navigasi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.collectorPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              )
            else
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: onViewDetail,
                  icon: const Icon(Icons.info_outline_rounded, size: 18),
                  label: const Text('Detail'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.collectorPrimary,
                    side: const BorderSide(color: AppColors.collectorPrimary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Terima'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.collectorPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )),
              ]),
          ]),
        ),
      ]),
    );
  }
}