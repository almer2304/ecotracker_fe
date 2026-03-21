import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      _phoneCtrl.text.trim(),
    );
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Buat Akun', style: AppTextStyles.h1),
              const SizedBox(height: 4),
              Text('Bergabung dan mulai berkontribusi untuk lingkungan',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 32),

              AppTextField(
                label: 'Nama Lengkap',
                hint: 'Masukkan nama lengkap',
                controller: _nameCtrl,
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.textHint),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Nama wajib diisi';
                  if (v.length < 2) return 'Nama minimal 2 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Email',
                hint: 'masukkan@email.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textHint),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email wajib diisi';
                  if (!v.contains('@')) return 'Format email tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Nomor HP',
                hint: '08xxxxxxxxxx',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textHint),
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length < 9) return 'Nomor HP tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Password',
                hint: 'Minimal 8 karakter',
                controller: _passwordCtrl,
                obscureText: !_showPassword,
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textHint),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textHint,
                  ),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password wajib diisi';
                  if (v.length < 8) return 'Password minimal 8 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              Consumer<AuthProvider>(
                builder: (_, auth, __) => Column(children: [
                  if (auth.error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(auth.error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))),
                      ]),
                    ),
                  GradientButton(
                    text: 'Daftar Sekarang',
                    onPressed: auth.isLoading ? null : _register,
                    isLoading: auth.isLoading,
                    icon: Icons.how_to_reg_rounded,
                  ),
                ]),
              ),

              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(children: [
                      TextSpan(text: 'Sudah punya akun? ', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      TextSpan(text: 'Masuk', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
    );
  }
}
