import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

// ============================================================
// LOADING WIDGETS
// ============================================================

class AppLoading extends StatelessWidget {
  final String? message;
  const AppLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: AppColors.primary),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(message!, style: AppTextStyles.bodyMedium),
        ],
      ]),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  final double height;
  const ShimmerCard({super.key, this.height = 100});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;
  const ShimmerList({super.key, this.count = 4, this.itemHeight = 100});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      itemBuilder: (_, __) => ShimmerCard(height: itemHeight),
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: iconColor ?? AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(title, style: AppTextStyles.h3, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(subtitle,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          if (buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: onButtonPressed,
                child: Text(buttonText!),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// ============================================================
// ERROR STATE
// ============================================================

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Terjadi Kesalahan', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: 160,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// ============================================================
// STATUS BADGE
// ============================================================

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config['color'].withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config['color'].withOpacity(0.3)),
      ),
      child: Text(
        config['label'],
        style: AppTextStyles.caption.copyWith(
          color: config['color'],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Map<String, dynamic> _getConfig(String status) {
    switch (status) {
      case 'pending':
        return {'color': AppColors.statusPending, 'label': 'Menunggu'};
      case 'assigned':
        return {'color': AppColors.statusAssigned, 'label': 'Ditugaskan'};
      case 'accepted':
        return {'color': AppColors.statusAssigned, 'label': 'Diterima'};
      case 'in_progress':
        return {'color': AppColors.statusInProgress, 'label': 'Dalam Perjalanan'};
      case 'arrived':
        return {'color': AppColors.statusArrived, 'label': 'Tiba'};
      case 'completed':
        return {'color': AppColors.statusCompleted, 'label': 'Selesai'};
      case 'cancelled':
        return {'color': AppColors.statusCancelled, 'label': 'Dibatalkan'};
      default:
        return {'color': AppColors.textSecondary, 'label': status};
    }
  }
}

// ============================================================
// GRADIENT BUTTON
// ============================================================

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final List<Color> colors;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.colors = const [AppColors.primary, AppColors.primaryDark],
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)],
                    Text(text, style: AppTextStyles.button),
                  ]),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// APP TEXT FIELD
// ============================================================

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: suffixIcon,
          prefixIcon: prefixIcon,
        ),
      ),
    ]);
  }
}

// ============================================================
// STAT CARD
// ============================================================

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 12),
        Text(value, style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption),
      ]),
    );
  }
}

// ============================================================
// SECTION HEADER
// ============================================================

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.h4),
        if (actionText != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionText!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
          ),
      ],
    );
  }
}
