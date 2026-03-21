import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (success && mounted) {
      // Navigate berdasarkan role
      final user = auth.user!;
      if (user.isCollector) {
        Navigator.pushReplacementNamed(context, '/collector-home');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 40),

              // Logo & Title
              Center(
                child: Column(children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      )],
                    ),
                    child: const Icon(Icons.eco_rounded, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text('EcoTracker', style: AppTextStyles.h1.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text('Bersama kita jaga lingkungan', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                ]),
              ),

              const SizedBox(height: 48),
              Text('Masuk', style: AppTextStyles.h2),
              const SizedBox(height: 4),
              Text('Selamat datang kembali!', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 32),

              // Email
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

              // Password
              AppTextField(
                label: 'Password',
                hint: '••••••••',
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
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Login Button
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
                    text: 'Masuk',
                    onPressed: auth.isLoading ? null : _login,
                    isLoading: auth.isLoading,
                    icon: Icons.login_rounded,
                  ),
                ]),
              ),

              const SizedBox(height: 24),

              // Register link
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/register'),
                  child: RichText(
                    text: TextSpan(children: [
                      TextSpan(text: 'Belum punya akun? ', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      TextSpan(text: 'Daftar sekarang', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ),
    );
  }
}
