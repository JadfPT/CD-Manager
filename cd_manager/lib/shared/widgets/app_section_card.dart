import 'package:flutter/material.dart';

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.2)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.surfaceContainerLow.withValues(alpha: 0.55),
              colors.surfaceContainer.withValues(alpha: 0.45),
            ],
          ),
        ),
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing ?? const SizedBox.shrink(),
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
