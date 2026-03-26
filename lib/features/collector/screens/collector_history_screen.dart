import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../pickup/models/pickup_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

// ── Provider ────────────────────────────────────────────────

class CollectorHistoryProvider extends ChangeNotifier {
  List<PickupModel> _pickups = [];
  bool _isLoading = false;
  String? _error;
  int _total = 0;
  int _page = 1;
  bool _hasMore = true;

  List<PickupModel> get pickups => _pickups;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  int get total => _total;

  final ApiClient _api = ApiClient();

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _pickups = [];
    }
    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.dio.get(
        '${ApiConstants.collectorAssigned.replaceAll('/assigned', '/history')}',
        queryParameters: {'page': _page, 'limit': 20},
      );
      if (res.data['success'] == true) {
        final data = res.data['data'];
        final List list = data['data'] ?? [];
        final newItems = list.map((e) => PickupModel.fromJson(e)).toList();
        _total = data['total'] ?? 0;
        _pickups = refresh ? newItems : [..._pickups, ...newItems];
        _hasMore = _pickups.length < _total;
        _page++;
        _error = null;
      }
    } on DioException catch (e) {
      _error = e.response?.data['error'] ?? 'Gagal memuat riwayat';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// ── Screen ────────────────────────────────────────────────

class CollectorHistoryScreen extends StatefulWidget {
  const CollectorHistoryScreen({super.key});

  @override
  State<CollectorHistoryScreen> createState() => _CollectorHistoryScreenState();
}

class _CollectorHistoryScreenState extends State<CollectorHistoryScreen> {
  late CollectorHistoryProvider _provider;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _provider = CollectorHistoryProvider();
    _provider.load();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      _provider.load();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Riwayat Pickup'),
          backgroundColor: AppColors.collectorPrimary,
          foregroundColor: Colors.white,
        ),
        body: Consumer<CollectorHistoryProvider>(
          builder: (_, provider, __) {
            if (provider.isLoading && provider.pickups.isEmpty) {
              return const AppLoading(message: 'Memuat riwayat...');
            }

            if (provider.pickups.isEmpty) {
              return Center(
                child: EmptyState(
                  icon: Icons.history_rounded,
                  title: 'Belum ada riwayat',
                  subtitle: 'Pickup yang sudah kamu selesaikan akan muncul di sini',
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.collectorPrimary,
              onRefresh: () => provider.load(refresh: true),
              child: Column(children: [
                // Summary bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: AppColors.collectorPrimary.withOpacity(0.08),
                  child: Text(
                    'Total ${provider.total} pickup diselesaikan',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.collectorPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.pickups.length + (provider.hasMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == provider.pickups.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _HistoryCard(pickup: provider.pickups[i]);
                    },
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final PickupModel pickup;
  const _HistoryCard({required this.pickup});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
            const SizedBox(width: 8),
            Text('Selesai', style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.success, fontWeight: FontWeight.w700)),
            const Spacer(),
            if (pickup.completedAt != null)
              Text(
                _formatDate(pickup.completedAt!),
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Alamat
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.location_on_rounded, color: AppColors.error, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(
                pickup.address,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )),
            ]),
            const SizedBox(height: 8),

            // User
            if (pickup.user != null)
              Row(children: [
                const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(pickup.user!.name, style: AppTextStyles.bodySmall),
              ]),
            const SizedBox(height: 12),

            // Stats
            Row(children: [
              _StatChip(
                icon: Icons.scale_rounded,
                label: pickup.totalWeight != null
                    ? '${pickup.totalWeight!.toStringAsFixed(2)} kg'
                    : '-',
                color: AppColors.collectorPrimary,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.stars_rounded,
                label: '${pickup.totalPointsAwarded ?? 0} poin',
                color: Colors.amber,
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption.copyWith(
          color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}