import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/report_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _severity = 'medium';
  double? _lat, _lon;
  bool _isGettingLocation = false;
  final List<File> _photos = [];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lon = pos.longitude;
        _addressCtrl.text = 'Lat: ${pos.latitude.toStringAsFixed(4)}, Lon: ${pos.longitude.toStringAsFixed(4)}';
      });
    } catch (_) {
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _addPhoto() async {
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 5 foto')));
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked != null) setState(() => _photos.add(File(picked.path)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan ambil lokasi terlebih dahulu'), backgroundColor: AppColors.error));
      return;
    }

    final success = await context.read<ReportProvider>().createReport(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      lat: _lat!,
      lon: _lon!,
      severity: _severity,
      photoPaths: _photos.map((f) => f.path).toList(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Laporan berhasil dikirim!'), backgroundColor: AppColors.success));
      Navigator.pop(context);
    } else if (mounted) {
      final err = context.read<ReportProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Gagal mengirim laporan'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporkan Area Kotor')),
      body: Consumer<ReportProvider>(
        builder: (_, provider, __) => Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              AppTextField(
                label: 'Judul Laporan',
                hint: 'Contoh: Tumpukan sampah di Jl. Merdeka',
                controller: _titleCtrl,
                validator: (v) => v == null || v.length < 5 ? 'Judul minimal 5 karakter' : null,
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Deskripsi',
                hint: 'Jelaskan kondisi area secara detail...',
                controller: _descCtrl,
                maxLines: 4,
                validator: (v) => v == null || v.length < 10 ? 'Deskripsi minimal 10 karakter' : null,
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Lokasi',
                hint: 'Alamat atau gunakan GPS',
                controller: _addressCtrl,
                suffixIcon: _isGettingLocation
                    ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                    : IconButton(icon: const Icon(Icons.my_location_rounded, color: AppColors.primary), onPressed: _getLocation),
                validator: (v) => v == null || v.isEmpty ? 'Lokasi wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Severity
              Text('Tingkat Keparahan', style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Row(children: [
                for (final s in ['low', 'medium', 'high'])
                  Expanded(child: Padding(
                    padding: EdgeInsets.only(right: s != 'high' ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _severity = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _severity == s ? _severityColor(s).withOpacity(0.15) : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _severity == s ? _severityColor(s) : Colors.transparent, width: 2),
                        ),
                        child: Column(children: [
                          Text(_severityEmoji(s), style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 4),
                          Text(_severityLabel(s), style: AppTextStyles.caption.copyWith(
                            color: _severity == s ? _severityColor(s) : AppColors.textSecondary,
                            fontWeight: _severity == s ? FontWeight.w600 : FontWeight.normal,
                          )),
                        ]),
                      ),
                    ),
                  )),
              ]),
              const SizedBox(height: 16),

              // Photos
              Text('Foto (maks. 5)', style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  ..._photos.map((f) => _photoItem(f)),
                  if (_photos.length < 5)
                    GestureDetector(
                      onTap: _addPhoto,
                      child: Container(
                        width: 80, height: 80, margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Icon(Icons.add_a_photo_rounded, color: AppColors.textHint),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 32),

              GradientButton(
                text: 'Kirim Laporan',
                icon: Icons.send_rounded,
                onPressed: provider.isSubmitting ? null : _submit,
                isLoading: provider.isSubmitting,
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _photoItem(File f) => Stack(children: [
    Container(
      width: 80, height: 80, margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(f, fit: BoxFit.cover)),
    ),
    Positioned(top: 2, right: 10, child: GestureDetector(
      onTap: () => setState(() => _photos.remove(f)),
      child: Container(
        width: 20, height: 20,
        decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
        child: const Icon(Icons.close, size: 12, color: Colors.white),
      ),
    )),
  ]);

  Color _severityColor(String s) {
    switch (s) {
      case 'low': return AppColors.success;
      case 'medium': return AppColors.warning;
      case 'high': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  String _severityEmoji(String s) {
    switch (s) { case 'low': return '🟢'; case 'medium': return '🟡'; case 'high': return '🔴'; default: return '🟡'; }
  }

  String _severityLabel(String s) {
    switch (s) { case 'low': return 'Rendah'; case 'medium': return 'Sedang'; case 'high': return 'Tinggi'; default: return 'Sedang'; }
  }
}
