import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/pickup_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class CreatePickupScreen extends StatefulWidget {
  const CreatePickupScreen({super.key});

  @override
  State<CreatePickupScreen> createState() => _CreatePickupScreenState();
}

class _CreatePickupScreenState extends State<CreatePickupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  File? _selectedPhoto;
  double? _lat;
  double? _lon;
  bool _isGettingLocation = false;
  double _uploadProgress = 0;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Layanan lokasi tidak aktif');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Izin lokasi ditolak');
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lon = pos.longitude;
        _addressCtrl.text = 'Lat: ${pos.latitude.toStringAsFixed(4)}, Lon: ${pos.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      _showError('Gagal mendapatkan lokasi');
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 1024);
    if (picked != null) setState(() => _selectedPhoto = File(picked.path));
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Pilih Foto', style: AppTextStyles.h4),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Kamera'),
            )),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton.icon(
              onPressed: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text('Galeri'),
            )),
          ]),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lon == null) {
      _showError('Silakan ambil lokasi terlebih dahulu');
      return;
    }

    final result = await context.read<PickupProvider>().createPickup(
      address: _addressCtrl.text.trim(),
      lat: _lat!,
      lon: _lon!,
      notes: _notesCtrl.text.trim(),
      photoPath: _selectedPhoto?.path,
      onProgress: (p) => setState(() => _uploadProgress = p),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Pickup berhasil dibuat! Sedang mencari collector...'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      final err = context.read<PickupProvider>().error;
      _showError(err ?? 'Gagal membuat pickup');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Pickup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<PickupProvider>(
        builder: (_, provider, __) {
          if (provider.isSubmitting) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                _uploadProgress > 0 ? 'Mengupload foto... ${(_uploadProgress * 100).toInt()}%' : 'Membuat pickup...',
                style: AppTextStyles.bodyMedium,
              ),
              if (_uploadProgress > 0) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: LinearProgressIndicator(value: _uploadProgress, color: AppColors.primary),
                ),
              ],
            ]));
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Photo upload
                Text('Foto Sampah', style: AppTextStyles.h4),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showImagePicker,
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider, width: 2),
                    ),
                    child: _selectedPhoto != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(_selectedPhoto!, fit: BoxFit.cover),
                          )
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.add_photo_alternate_rounded, size: 48, color: AppColors.textHint),
                            const SizedBox(height: 8),
                            Text('Tambah foto sampah', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
                            Text('(opsional)', style: AppTextStyles.caption),
                          ]),
                  ),
                ),
                const SizedBox(height: 24),

                // Address
                AppTextField(
                  label: 'Alamat Pickup',
                  hint: 'Masukkan alamat atau gunakan GPS',
                  controller: _addressCtrl,
                  maxLines: 2,
                  suffixIcon: _isGettingLocation
                      ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                      : IconButton(icon: const Icon(Icons.my_location_rounded, color: AppColors.primary), onPressed: _getLocation),
                  validator: (v) => v == null || v.isEmpty ? 'Alamat wajib diisi' : null,
                ),
                const SizedBox(height: 8),

                if (_lat != null && _lon != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      const Icon(Icons.location_on, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text('${_lat!.toStringAsFixed(4)}, ${_lon!.toStringAsFixed(4)}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                    ]),
                  ),
                const SizedBox(height: 16),

                // Notes
                AppTextField(
                  label: 'Catatan (opsional)',
                  hint: 'Contoh: Sampah di depan pagar, ring bell dua kali...',
                  controller: _notesCtrl,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.info.withOpacity(0.2)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(
                      'Setelah pickup dibuat, sistem akan otomatis mencari collector terdekat yang tersedia.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
                    )),
                  ]),
                ),
                const SizedBox(height: 24),

                GradientButton(
                  text: 'Buat Pickup',
                  icon: Icons.send_rounded,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
              ]),
            ),
          );
        },
      ),
    );
  }
}
