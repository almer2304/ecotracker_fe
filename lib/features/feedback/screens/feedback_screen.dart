import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../pickup/providers/pickup_provider.dart';

// ============================================================
// MODEL
// ============================================================

class FeedbackModel {
  final String id;
  final String userId;
  final String? pickupId;
  final String feedbackType;
  final int? rating;
  final String? title;
  final String? comment;
  final List<String> tags;
  final String? adminResponse;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.userId,
    this.pickupId,
    required this.feedbackType,
    this.rating,
    this.title,
    this.comment,
    this.tags = const [],
    this.adminResponse,
    required this.createdAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      pickupId: json['pickup_id'],
      feedbackType: json['feedback_type'] ?? 'general',
      rating: json['rating'],
      title: json['title'],
      comment: json['comment'],
      tags: List<String>.from(json['tags'] ?? []),
      adminResponse: json['admin_response'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

// ============================================================
// PROVIDER
// ============================================================

class FeedbackProvider extends ChangeNotifier {
  List<FeedbackModel> _feedbacks = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  List<FeedbackModel> get feedbacks => _feedbacks;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  final ApiClient _api = ApiClient();

  Future<void> loadMyFeedback() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.get(ApiConstants.myFeedback);
      if (res.data['success'] == true) {
        final List list = res.data['data']['data'] ?? [];
        _feedbacks = list.map((e) => FeedbackModel.fromJson(e)).toList();
        _error = null;
      }
    } on DioException catch (e) {
      _error = e.response?.data['error'] ?? 'Gagal memuat feedback';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitFeedback({
    required String feedbackType,
    String? pickupId,
    int? rating,
    String? title,
    String? comment,
    List<String> tags = const [],
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      final data = <String, dynamic>{
        'feedback_type': feedbackType,
        if (pickupId != null) 'pickup_id': pickupId,
        if (rating != null) 'rating': rating,
        if (title != null && title.isNotEmpty) 'title': title,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        'tags': tags,
      };
      final res = await _api.dio.post(ApiConstants.feedback, data: data);
      if (res.data['success'] == true) return true;
      _error = res.data['error'] ?? 'Gagal mengirim feedback';
    } on DioException catch (e) {
      _error = e.response?.data['error'] ?? 'Koneksi gagal';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
    return false;
  }
}

// ============================================================
// SCREEN
// ============================================================

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  String _feedbackType = 'general';
  int _rating = 0;
  final _titleCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  String? _selectedPickupId;
  final Set<String> _selectedTags = {};

  final List<String> _availableTags = [
    'Fast Service', 'Friendly', 'Professional',
    'On Time', 'Clean Work', 'Good Communication',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final provider = context.read<FeedbackProvider>();
    final success = await provider.submitFeedback(
      feedbackType: _feedbackType,
      pickupId: _selectedPickupId,
      rating: _feedbackType == 'collector' && _rating > 0 ? _rating : null,
      title: _titleCtrl.text.trim(),
      comment: _commentCtrl.text.trim(),
      tags: _selectedTags.toList(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Feedback berhasil dikirim, terima kasih!'), backgroundColor: AppColors.success));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beri Feedback')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Feedback type
          Text('Jenis Feedback', style: AppTextStyles.h4),
          const SizedBox(height: 12),
          Row(children: [
            for (final type in [
              {'value': 'app', 'label': 'Aplikasi', 'icon': Icons.phone_android_rounded},
              {'value': 'collector', 'label': 'Collector', 'icon': Icons.person_rounded},
              {'value': 'general', 'label': 'Umum', 'icon': Icons.chat_bubble_outline_rounded},
            ])
              Expanded(child: Padding(
                padding: EdgeInsets.only(right: type['value'] != 'general' ? 8 : 0),
                child: GestureDetector(
                  onTap: () => setState(() => _feedbackType = type['value'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _feedbackType == type['value'] ? AppColors.primarySurface : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _feedbackType == type['value'] ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(children: [
                      Icon(type['icon'] as IconData,
                          color: _feedbackType == type['value'] ? AppColors.primary : AppColors.textSecondary, size: 24),
                      const SizedBox(height: 4),
                      Text(type['label'] as String,
                          style: AppTextStyles.caption.copyWith(
                            color: _feedbackType == type['value'] ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: _feedbackType == type['value'] ? FontWeight.w600 : FontWeight.normal,
                          )),
                    ]),
                  ),
                ),
              )),
          ]),
          const SizedBox(height: 24),

          // Rating (only for collector)
          if (_feedbackType == 'collector') ...[
            Text('Rating', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber, size: 40,
                  ),
                ),
              );
            })),
            const SizedBox(height: 24),

            // Select pickup for collector feedback
            Consumer<PickupProvider>(
              builder: (_, pickupProvider, __) {
                final completed = pickupProvider.pickups.where((p) => p.isCompleted).toList();
                if (completed.isEmpty) return const SizedBox();
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Pilih Pickup', style: AppTextStyles.h4),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedPickupId,
                    hint: Text('Pilih pickup yang ingin di-review', style: AppTextStyles.bodySmall),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: completed.map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.address.length > 40 ? '${p.address.substring(0, 40)}...' : p.address,
                          style: AppTextStyles.bodySmall),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedPickupId = v),
                  ),
                  const SizedBox(height: 24),
                ]);
              },
            ),
          ],

          // Title
          AppTextField(
            label: 'Judul (opsional)',
            hint: 'Ringkasan feedback kamu',
            controller: _titleCtrl,
          ),
          const SizedBox(height: 16),

          // Comment
          AppTextField(
            label: 'Komentar',
            hint: 'Ceritakan pengalaman kamu...',
            controller: _commentCtrl,
            maxLines: 4,
          ),
          const SizedBox(height: 16),

          // Tags
          Text('Tag', style: AppTextStyles.h4),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: _availableTags.map((tag) {
            final selected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) _selectedTags.remove(tag);
                else _selectedTags.add(tag);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primarySurface : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? AppColors.primary : Colors.transparent),
                ),
                child: Text(tag, style: AppTextStyles.bodySmall.copyWith(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                )),
              ),
            );
          }).toList()),
          const SizedBox(height: 32),

          Consumer<FeedbackProvider>(
            builder: (_, provider, __) => Column(children: [
              if (provider.error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(provider.error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                ),
              GradientButton(
                text: 'Kirim Feedback',
                icon: Icons.send_rounded,
                onPressed: provider.isSubmitting ? null : _submit,
                isLoading: provider.isSubmitting,
              ),
            ]),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}
