import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/report_provider.dart';
import '../models/report_model.dart';
import 'create_report_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadMyReports(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Saya')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateReportScreen()))
            .then((_) => context.read<ReportProvider>().loadMyReports(refresh: true)),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Laporan Baru', style: TextStyle(color: Colors.white)),
      ),
      body: Consumer<ReportProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading && provider.reports.isEmpty) return const ShimmerList(count: 4, itemHeight: 120);
          if (provider.error != null && provider.reports.isEmpty) {
            return ErrorState(message: provider.error!, onRetry: () => provider.loadMyReports(refresh: true));
          }
          if (provider.reports.isEmpty) {
            return EmptyState(
              icon: Icons.report_rounded,
              title: 'Belum ada laporan',
              subtitle: 'Laporkan area kotor di sekitarmu!',
              iconColor: AppColors.warning,
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => provider.loadMyReports(refresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.reports.length,
              itemBuilder: (_, i) => _ReportCard(report: provider.reports[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  const _ReportCard({required this.report});

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _severityColor(report.severity).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_severityLabel(report.severity),
                style: AppTextStyles.caption.copyWith(color: _severityColor(report.severity), fontWeight: FontWeight.w600)),
          ),
          const Spacer(),
          StatusBadge(status: report.status),
        ]),
        const SizedBox(height: 10),
        Text(report.title, style: AppTextStyles.h4, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(report.address, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Text(DateFormat('dd MMM yyyy').format(report.createdAt.toLocal()),
            style: AppTextStyles.caption),
        if (report.photoUrls.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: report.photoUrls.length,
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(report.photoUrls[i],
                    width: 60, height: 60, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60, height: 60, color: AppColors.surfaceVariant,
                      child: const Icon(Icons.image_not_supported, color: AppColors.textHint),
                    )),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Color _severityColor(String s) {
    switch (s) {
      case 'low': return AppColors.success;
      case 'medium': return AppColors.warning;
      case 'high': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  String _severityLabel(String s) {
    switch (s) { case 'low': return 'Rendah'; case 'medium': return 'Sedang'; case 'high': return 'Tinggi'; default: return s; }
  }
}
