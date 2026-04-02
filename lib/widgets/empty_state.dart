import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon, 
            size: 64, 
            color: AppTheme.textSecondary.withValues(alpha: 0.5)
          ),
          const SizedBox(height: 16),
          Text(
            title, 
            style: Theme.of(context).textTheme.titleLarge
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!, 
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              )
            ),
          ],
        ],
      ),
    );
  }
}
