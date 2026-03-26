import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pickup/providers/pickup_provider.dart';
import '../../pickup/models/pickup_model.dart';
import '../../pickup/screens/my_pickups_screen.dart';
import '../../pickup/screens/create_pickup_screen.dart';
import '../../badge/screens/badges_screen.dart';
import '../../report/screens/my_reports_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _UserDashboard(),
    MyPickupsScreen(),
    MyReportsScreen(),
    BadgesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.recycling_rounded), label: 'Pickup'),
          BottomNavigationBarItem(icon: Icon(Icons.report_rounded), label: 'Laporan'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: 'Badge'),
        ],
      ),
    );
  }
}

class _UserDashboard extends StatefulWidget {
  const _UserDashboard();

  @override
  State<_UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<_UserDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshProfile();
      context.read<PickupProvider>().loadMyPickups(refresh: true);
    });
  }

  // Burger menu drawer
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
            // Handle bar
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Profile tile
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(
                  (auth.user?.name ?? 'U')[0].toUpperCase(),
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(auth.user?.name ?? '', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(auth.user?.email ?? '', style: AppTextStyles.caption),
            ),
            const Divider(height: 1),

            // Profile menu
            ListTile(
              leading: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
              title: const Text('Profil Saya'),
              onTap: () {
                Navigator.pop(context);
                _showProfileDialog(context, auth);
              },
            ),

            // About menu
            ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
              title: const Text('Tentang EcoTracker'),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),

            const Divider(height: 1),

            // Logout
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text('Keluar', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
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
        title: const Text('Profil Saya'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _profileRow(Icons.person_rounded, 'Nama', auth.user?.name ?? '-'),
          const SizedBox(height: 12),
          _profileRow(Icons.email_rounded, 'Email', auth.user?.email ?? '-'),
          const SizedBox(height: 12),
          _profileRow(Icons.phone_rounded, 'Telepon', auth.user?.phone ?? '-'),
          const SizedBox(height: 12),
          _profileRow(Icons.stars_rounded, 'Total Poin', '${auth.user?.totalPoints ?? 0}'),
          const SizedBox(height: 12),
          _profileRow(Icons.recycling_rounded, 'Total Pickup', '${auth.user?.totalPickupsCompleted ?? 0}'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      ]),
    ]);
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.eco_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('EcoTracker'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Versi 2.0', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Text(
            'EcoTracker adalah platform manajemen pengambilan sampah daur ulang yang menghubungkan user dengan collector terdekat secara otomatis.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          Text('Bersama kita jaga lingkungan 🌿', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await context.read<AuthProvider>().refreshProfile();
          await context.read<PickupProvider>().loadMyPickups(refresh: true);
        },
        child: CustomScrollView(slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,   // dikurangi dari 200 → fix overflow
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.primary,
            // Ganti logout icon dengan burger menu
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => _showMenu(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Consumer<AuthProvider>(
                builder: (_, auth, __) => Container(
                  decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 16), // top dikurangi
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                    Row(children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: Text(
                          (auth.user?.name ?? 'U')[0].toUpperCase(),
                          style: AppTextStyles.h4.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Halo,', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                        Text(auth.user?.name ?? '', style: AppTextStyles.h4.copyWith(color: Colors.white),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ])),
                    ]),
                    const SizedBox(height: 12),
                    // Points card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.stars_rounded, color: Colors.amber, size: 24),
                        const SizedBox(width: 10),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Total Poin', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                          Text('${auth.user?.totalPoints ?? 0}',
                              style: AppTextStyles.h3.copyWith(color: Colors.white)),
                        ]),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Request Pickup Button
                GradientButton(
                  text: 'Request Pickup Sekarang',
                  icon: Icons.add_circle_outline_rounded,
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CreatePickupScreen())),
                ),
                const SizedBox(height: 24),

                // Stats
                Consumer2<AuthProvider, PickupProvider>(
                  builder: (_, auth, pickup, __) => Row(children: [
                    Expanded(child: StatCard(
                      label: 'Total Pickup',
                      value: '${auth.user?.totalPickupsCompleted ?? 0}',
                      icon: Icons.recycling_rounded,
                      color: AppColors.primary,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: StatCard(
                      label: 'Laporan',
                      value: '${auth.user?.totalReportsSubmitted ?? 0}',
                      icon: Icons.report_rounded,
                      color: AppColors.warning,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: StatCard(
                      label: 'CO₂ Hemat',
                      value: '${((auth.user?.totalPickupsCompleted ?? 0) * 0.5).toStringAsFixed(1)}kg',
                      icon: Icons.eco_rounded,
                      color: AppColors.success,
                    )),
                  ]),
                ),
                const SizedBox(height: 24),

                // Recent pickups
                SectionHeader(
                  title: 'Pickup Terbaru',
                  actionText: 'Lihat Semua',
                  onAction: () {},
                ),
                const SizedBox(height: 12),

                Consumer<PickupProvider>(
                  builder: (_, provider, __) {
                    if (provider.isLoading && provider.pickups.isEmpty) {
                      return const ShimmerCard(height: 100);
                    }
                    if (provider.pickups.isEmpty) {
                      return EmptyState(
                        icon: Icons.recycling_rounded,
                        title: 'Belum ada pickup',
                        subtitle: 'Mulai request pickup pertamamu!',
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.pickups.take(3).length,
                      itemBuilder: (_, i) => _RecentPickupCard(pickup: provider.pickups[i]),
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
}

class _RecentPickupCard extends StatelessWidget {
  final PickupModel pickup;
  const _RecentPickupCard({required this.pickup});

  Future<void> _openLocation(double lat, double lon) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: pickup.photoUrl != null
                ? Image.network(pickup.photoUrl!, width: 56, height: 56, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderImage())
                : _placeholderImage(),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pickup.address, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            if (pickup.collector != null)
              Text('Collector: ${pickup.collector!.name}', style: AppTextStyles.bodySmall),
          ])),
          StatusBadge(status: pickup.status),
        ]),

        // Tombol lihat lokasi
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _openLocation(pickup.lat, pickup.lon),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text('Lihat Lokasi Pickup', style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              )),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.recycling, color: AppColors.primary, size: 28),
    );
  }
}