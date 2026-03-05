import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ignore: must_be_immutable
class AppDrawer extends StatelessWidget {
  final String role;
  final String? classId;
  const AppDrawer({super.key, required this.role, this.classId});

  @override
  Widget build(BuildContext context) {
    return const SizedBox
        .shrink(); // placeholder, nav is handled by AppBar actions
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final String? paidLabel;
  final String? unpaidLabel;

  const StatusBadge(
      {super.key,
      required this.status,
      this.paidLabel = 'Paid',
      this.unpaidLabel = 'Unpaid'});

  bool get _isPaid => status == 'paid';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _isPaid
            ? AppTheme.paidGreen.withOpacity(0.12)
            : AppTheme.unpaidRed.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: _isPaid
                ? AppTheme.paidGreen.withOpacity(0.3)
                : AppTheme.unpaidRed.withOpacity(0.3)),
      ),
      child: Text(
        _isPaid ? (paidLabel ?? 'Paid') : (unpaidLabel ?? 'Unpaid'),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _isPaid ? AppTheme.paidGreen : AppTheme.unpaidRed,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader(
      {super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      this.subtitle,
      this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 72, color: AppTheme.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
