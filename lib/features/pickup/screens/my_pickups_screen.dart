import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/pickup_provider.dart';
import '../models/pickup_model.dart';
import 'pickup_detail_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class MyPickupsScreen extends StatefulWidget {
  const MyPickupsScreen({super.key});

  @override
  State<MyPickupsScreen> createState() => _MyPickupsScreenState();
}

class _MyPickupsScreenState extends State<MyPickupsScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PickupProvider>().loadMyPickups(refresh: true);
    });
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        context.read<PickupProvider>().loadMyPickups();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pickup Saya')),
      body: Consumer<PickupProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading && provider.pickups.isEmpty) {
            return const ShimmerList(count: 4, itemHeight: 120);
          }
          if (provider.error != null && provider.pickups.isEmpty) {
            return ErrorState(message: provider.error!, onRetry: () => provider.loadMyPickups(refresh: true));
          }
          if (provider.pickups.isEmpty) {
            return EmptyState(
              icon: Icons.recycling_rounded,
              title: 'Belum ada pickup',
              subtitle: 'Request pickup pertamamu sekarang!',
              buttonText: 'Buat Pickup',
              onButtonPressed: () => Navigator.pushNamed(context, '/create-pickup'),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => provider.loadMyPickups(refresh: true),
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: provider.pickups.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == provider.pickups.length) {
                  return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                }
                return PickupCard(pickup: provider.pickups[i]);
              },
            ),
          );
        },
      ),
    );
  }
}

class PickupCard extends StatelessWidget {
  final PickupModel pickup;
  const PickupCard({super.key, required this.pickup});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PickupDetailScreen(pickup: pickup)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(pickup.status).withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              const Icon(Icons.recycling_rounded, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(child: Text(
                DateFormat('dd MMM yyyy, HH:mm').format(pickup.createdAt.toLocal()),
                style: AppTextStyles.caption,
              )),
              StatusBadge(status: pickup.status),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: pickup.photoUrl != null
                    ? Image.network(pickup.photoUrl!, width: 70, height: 70, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(pickup.address,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                _buildStatusInfo(pickup),
                if (pickup.isCompleted && pickup.totalPointsAwarded != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text('+${pickup.totalPointsAwarded} poin',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.warning, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ],
              ])),
            ]),
          ),

          // Tap hint jika completed
          if (pickup.isCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.star_outline_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('Tap untuk lihat detail & beri rating',
                    style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              ]),
            ),
        ]),
      ),
    );
  }

  Widget _buildStatusInfo(PickupModel pickup) {
    switch (pickup.status) {
      case 'assigned':
      case 'accepted':
        return Row(children: [
          const Icon(Icons.person_outline, size: 14, color: AppColors.statusAssigned),
          const SizedBox(width: 4),
          Text(pickup.collector?.name ?? 'Collector ditugaskan',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.statusAssigned)),
        ]);
      case 'in_progress':
        return Row(children: [
          const Icon(Icons.directions_car_rounded, size: 14, color: AppColors.statusInProgress),
          const SizedBox(width: 4),
          Text('Collector sedang menuju lokasi',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.statusInProgress)),
        ]);
      case 'arrived':
        return Row(children: [
          const Icon(Icons.location_on_rounded, size: 14, color: AppColors.statusArrived),
          const SizedBox(width: 4),
          Text('Collector sudah tiba!',
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.statusArrived, fontWeight: FontWeight.w600)),
        ]);
      case 'completed':
        return Row(children: [
          const Icon(Icons.check_circle_outline, size: 14, color: AppColors.statusCompleted),
          const SizedBox(width: 4),
          Text('${pickup.totalWeight?.toStringAsFixed(1) ?? 0} kg dikumpulkan',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.statusCompleted)),
        ]);
      default:
        return Text('Mencari collector terdekat...',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary));
    }
  }

  Widget _placeholder() {
    return Container(
      width: 70, height: 70,
      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.recycling, color: AppColors.primary, size: 32),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.statusPending;
      case 'assigned': case 'accepted': return AppColors.statusAssigned;
      case 'in_progress': return AppColors.statusInProgress;
      case 'arrived': return AppColors.statusArrived;
      case 'completed': return AppColors.statusCompleted;
      default: return AppColors.textSecondary;
    }
  }
}