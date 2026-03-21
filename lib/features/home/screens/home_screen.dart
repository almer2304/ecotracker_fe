import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pickup/providers/pickup_provider.dart';
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
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Consumer<AuthProvider>(
                builder: (_, auth, __) => Container(
                  decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: Text(
                          (auth.user?.name ?? 'U')[0].toUpperCase(),
                          style: AppTextStyles.h3.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Halo,', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                        Text(auth.user?.name ?? '', style: AppTextStyles.h4.copyWith(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ])),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Colors.white),
                        onPressed: () async {
                          await context.read<AuthProvider>().logout();
                          if (mounted) Navigator.pushReplacementNamed(context, '/login');
                        },
                      ),
                    ]),
                    const SizedBox(height: 16),
                    // Points card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
                        const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Total Poin', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                          Text('${auth.user?.totalPoints ?? 0}', style: AppTextStyles.h2.copyWith(color: Colors.white)),
                        ]),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
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
  final dynamic pickup;
  const _RecentPickupCard({required this.pickup});

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
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: pickup.photoUrl != null
              ? Image.network(pickup.photoUrl, width: 56, height: 56, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderImage())
              : _placeholderImage(),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(pickup.address, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          if (pickup.collector != null)
            Text('Collector: ${pickup.collector.name}', style: AppTextStyles.bodySmall),
        ])),
        StatusBadge(status: pickup.status),
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
