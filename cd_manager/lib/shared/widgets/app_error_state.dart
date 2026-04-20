import 'package:flutter/material.dart';

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: colors.errorContainer.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.error.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 36, color: colors.error),
              const SizedBox(height: 14),
              Text(
                'Ocorreu um erro',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
