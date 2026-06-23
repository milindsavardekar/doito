import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Page Header ─────────────────────────────────────────────────────────────
/// The ONE header style every screen's page title should use — gradient
/// background, fixed font/size/weight, optional subtitle and trailing
/// action. Using this everywhere (instead of each screen rolling its own
/// Container + Text) is what keeps every page's header looking like part
/// of the same app instead of each page feeling hand-built.
///
/// Use this for plain "page title" headers. Dashboard-style headers (Home,
/// Provider Home greeting bars) and hero/profile headers (avatar + name,
/// cover photos) are intentionally a different, richer layout and aren't
/// meant to be replaced by this — but their title text should still use
/// [AppTheme.appBarTitleStyle] so the font itself stays consistent.
class PageHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? leading;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.actions,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.primary,
      elevation: 0,
      automaticallyImplyLeading: showBackButton,
      leading: leading ??
          (showBackButton
              ? const BackButton(color: Colors.white)
              : null),
      titleTextStyle: AppTheme.appBarTitleStyle(color: Colors.white),
      title: subtitle == null
          ? Text(title)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppTheme.appBarTitleStyle(color: Colors.white)),
                Text(subtitle!,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: actions,
    );
  }
}

// ── Gradient Button ────────────────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double? width;
  final double height;
  final bool isLoading;
  final IconData? icon;
  final LinearGradient? gradient;

  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.width,
    this.height = 54,
    this.isLoading = false,
    this.icon,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: gradient ?? AppTheme.accentGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        )),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Status Badge ───────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  Color get _color => switch (status.toLowerCase()) {
        'confirmed' => AppTheme.primary,
        'in_progress' => AppTheme.warning,
        'completed' => AppTheme.success,
        'cancelled' => AppTheme.error,
        'pending' => AppTheme.accent,
        _ => AppTheme.textLight,
      };

  String get _label => switch (status.toLowerCase()) {
        'in_progress' => 'In Progress',
        _ => status[0].toUpperCase() + status.substring(1),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(_label,
              style: TextStyle(
                  color: _color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Rating Stars ───────────────────────────────────────────────────────────────
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  const RatingStars({super.key, required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: AppTheme.accent, size: size),
        const SizedBox(width: 3),
        Text(rating.toStringAsFixed(1),
            style: TextStyle(
                fontSize: size - 2,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
      ],
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

// ── App Text Field ─────────────────────────────────────────────────────────────
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final int maxLines;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffix,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppTheme.textLight, size: 20)
                : null,
            suffix: suffix,
          ),
        ),
      ],
    );
  }
}

// ── Shimmer placeholder ────────────────────────────────────────────────────────
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const ShimmerBox(
      {super.key, required this.width, required this.height, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
          color: AppTheme.divider,
          borderRadius: BorderRadius.circular(radius)),
    );
  }
}
