import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/badge_model.dart';
import '../providers/badge_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/providers/auth_provider.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BadgeProvider>().loadMyBadges();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pencapaian')),
      body: Consumer2<BadgeProvider, AuthProvider>(
        builder: (_, badgeProvider, authProvider, __) {
          if (badgeProvider.isLoading) return const ShimmerList(count: 6, itemHeight: 100);
          if (badgeProvider.error != null) {
            return ErrorState(message: badgeProvider.error!, onRetry: badgeProvider.loadMyBadges);
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: badgeProvider.loadMyBadges,
            child: CustomScrollView(slivers: [
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Column(children: [
                    const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      '${authProvider.user?.totalPoints ?? 0}',
                      style: AppTextStyles.pointsLarge,
                    ),
                    Text('Total Poin', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${badgeProvider.unlockedCount}/${badgeProvider.badges.length} Badge Diraih',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _BadgeCard(
                      badge: badgeProvider.badges[i],
                      user: authProvider.user,
                    ),
                    childCount: badgeProvider.badges.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ]),
          );
        },
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final BadgeModel badge;
  final dynamic user;
  const _BadgeCard({required this.badge, this.user});

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.isUnlocked == true;
    final progress = _getProgress();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: unlocked
            ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: unlocked
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: unlocked ? AppColors.primarySurface : AppColors.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(badge.emoji, style: TextStyle(fontSize: unlocked ? 32 : 28)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          badge.name,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: unlocked ? AppColors.textPrimary : AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
        const SizedBox(height: 4),
        Text(
          badge.criteriaType == 'pickups'
              ? '${badge.criteriaValue} pickup'
              : badge.criteriaType == 'points'
                  ? '${badge.criteriaValue} poin'
                  : '${badge.criteriaValue} laporan',
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        if (!unlocked) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceVariant,
              color: AppColors.primary,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * badge.criteriaValue).toInt()}/${badge.criteriaValue}',
            style: AppTextStyles.caption.copyWith(color: AppColors.primary),
          ),
        ] else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '✓ Diraih',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ]),
    );
  }

  double _getProgress() {
    if (user == null) return 0;
    switch (badge.criteriaType) {
      case 'pickups':
        return (user.totalPickupsCompleted ?? 0) / badge.criteriaValue;
      case 'points':
        return (user.totalPoints ?? 0) / badge.criteriaValue;
      case 'reports':
        return (user.totalReportsSubmitted ?? 0) / badge.criteriaValue;
      default:
        return 0;
    }
  }
}
