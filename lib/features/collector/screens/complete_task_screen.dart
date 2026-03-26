import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/collector_provider.dart';
import '../../pickup/models/pickup_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class CompleteTaskScreen extends StatefulWidget {
  final String pickupId;
  const CompleteTaskScreen({super.key, required this.pickupId});

  @override
  State<CompleteTaskScreen> createState() => _CompleteTaskScreenState();
}

class _CompleteTaskScreenState extends State<CompleteTaskScreen> {
  final List<_WasteItem> _items = [];
  bool _isCompleting = false; // ← loading state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CollectorProvider>().loadCategories();
    });
  }

  void _addItem() {
    final categories = context.read<CollectorProvider>().categories;
    if (categories.isEmpty) return;
    setState(() => _items.add(_WasteItem(categoryId: categories.first.id, category: categories.first)));
  }

  double get _totalWeight => _items.fold(0, (sum, i) => sum + i.weightKg);
  int get _totalPoints => _items.fold(0, (sum, i) => sum + i.points);

  Future<void> _complete() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 item sampah'), backgroundColor: AppColors.error));
      return;
    }

    final invalid = _items.where((i) => i.weightKg <= 0).isNotEmpty;
    if (invalid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berat semua item harus lebih dari 0'), backgroundColor: AppColors.error));
      return;
    }

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Selesai'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Total berat: ${_totalWeight.toStringAsFixed(2)} kg'),
          Text('Total poin untuk user: $_totalPoints poin'),
          const SizedBox(height: 8),
          const Text('Yakin pickup sudah selesai?'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.collectorPrimary),
            child: const Text('Ya, Selesai'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Tampilkan loading overlay
    setState(() => _isCompleting = true);

    final items = _items.map((i) => {'category_id': i.categoryId, 'weight_kg': i.weightKg}).toList();
    final success = await context.read<CollectorProvider>().completePickup(widget.pickupId, items);

    if (!mounted) return;

    setState(() => _isCompleting = false);

    if (success) {
      // Tampilkan success dialog lalu auto redirect
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 16),
            Text('Pickup Selesai!', style: AppTextStyles.h3.copyWith(color: AppColors.success)),
            const SizedBox(height: 8),
            Text(
              'Poin telah diberikan ke user.\nTotal: $_totalPoints poin dari ${_totalWeight.toStringAsFixed(2)} kg sampah.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );

      if (mounted) {
        // Auto redirect ke dashboard (clear semua route di atas)
        Navigator.popUntil(context, (r) => r.isFirst);
      }
    } else {
      // Tampilkan error
      final err = context.read<CollectorProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Gagal menyelesaikan pickup'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Selesaikan Pickup'),
            backgroundColor: AppColors.collectorPrimary,
            foregroundColor: Colors.white,
          ),
          body: Consumer<CollectorProvider>(
            builder: (_, provider, __) {
              if (provider.categories.isEmpty) return const AppLoading(message: 'Memuat kategori...');

              return Column(children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Header info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.collectorSurface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(children: [
                          const Icon(Icons.info_outline, color: AppColors.collectorPrimary),
                          const SizedBox(width: 12),
                          Expanded(child: Text(
                            'Masukkan detail sampah yang dikumpulkan. Poin dihitung otomatis berdasarkan berat dan kategori.',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.collectorPrimaryDark),
                          )),
                        ]),
                      ),
                      const SizedBox(height: 20),

                      // Items list
                      if (_items.isEmpty)
                        Center(child: Column(children: [
                          const Icon(Icons.add_box_outlined, size: 48, color: AppColors.textHint),
                          const SizedBox(height: 8),
                          Text('Belum ada item', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                        ]))
                      else
                        ...List.generate(_items.length, (i) => _WasteItemCard(
                          item: _items[i],
                          categories: provider.categories,
                          index: i + 1,
                          onDelete: () => setState(() => _items.removeAt(i)),
                          onChanged: () => setState(() {}),
                        )),

                      const SizedBox(height: 12),

                      // Add item button
                      OutlinedButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Tambah Item Sampah'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.collectorPrimary,
                          side: const BorderSide(color: AppColors.collectorPrimary),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ]),
                  ),
                ),

                // Summary & complete button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [BoxShadow(color: AppColors.shadowMedium, blurRadius: 12, offset: const Offset(0, -4))],
                  ),
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Total Berat', style: AppTextStyles.caption),
                        Text('${_totalWeight.toStringAsFixed(2)} kg', style: AppTextStyles.h3),
                      ])),
                      Container(width: 1, height: 40, color: AppColors.divider),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('Total Poin untuk User', style: AppTextStyles.caption),
                        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text('$_totalPoints', style: AppTextStyles.h3.copyWith(color: AppColors.warning)),
                        ]),
                      ])),
                    ]),
                    const SizedBox(height: 16),
                    GradientButton(
                      text: 'Selesaikan Pickup',
                      icon: Icons.done_all_rounded,
                      colors: [AppColors.collectorPrimary, AppColors.collectorPrimaryDark],
                      onPressed: _isCompleting ? null : _complete,
                    ),
                  ]),
                ),
              ]);
            },
          ),
        ),

        // ── Loading overlay saat proses complete ──────────────────────
        if (_isCompleting)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(color: AppColors.collectorPrimary),
                  const SizedBox(height: 16),
                  Text('Menyelesaikan pickup...', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 4),
                  Text('Mohon tunggu sebentar', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                ]),
              ),
            ),
          ),
      ],
    );
  }
}

class _WasteItem {
  String categoryId;
  WasteCategory category;
  double weightKg;

  _WasteItem({required this.categoryId, required this.category, this.weightKg = 0});

  int get points => (weightKg * category.pointsPerKg).round();
}

class _WasteItemCard extends StatefulWidget {
  final _WasteItem item;
  final List<WasteCategory> categories;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _WasteItemCard({
    required this.item,
    required this.categories,
    required this.index,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<_WasteItemCard> createState() => _WasteItemCardState();
}

class _WasteItemCardState extends State<_WasteItemCard> {
  late TextEditingController _weightCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.item.weightKg > 0 ? widget.item.weightKg.toString() : '',
    );
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Item ${widget.index}', style: AppTextStyles.h4.copyWith(color: AppColors.collectorPrimary)),
          const Spacer(),
          GestureDetector(
            onTap: widget.onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // Category dropdown
        DropdownButtonFormField<String>(
          value: widget.item.categoryId,
          decoration: InputDecoration(
            labelText: 'Kategori',
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: widget.categories.map((cat) => DropdownMenuItem(
            value: cat.id,
            child: Text('${cat.name} (${cat.pointsPerKg} poin/kg)', style: AppTextStyles.bodySmall),
          )).toList(),
          onChanged: (v) {
            if (v != null) {
              widget.item.categoryId = v;
              widget.item.category = widget.categories.firstWhere((c) => c.id == v);
              widget.onChanged();
            }
          },
        ),
        const SizedBox(height: 12),

        // Weight input + poin preview
        Row(children: [
          Expanded(child: TextFormField(
            controller: _weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Berat (kg)',
              suffixText: 'kg',
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (v) {
              widget.item.weightKg = double.tryParse(v) ?? 0;
              widget.onChanged();
            },
          )),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
              Text(
                '${widget.item.points}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text('poin', style: AppTextStyles.caption),
            ]),
          ),
        ]),
      ]),
    );
  }
}