import 'package:flutter/material.dart';

class ShelfStatusChip extends StatelessWidget {
  const ShelfStatusChip({
    required this.onShelf,
    super.key,
  });

  final bool onShelf;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = onShelf
        ? colors.primaryContainer.withValues(alpha: 0.7)
        : colors.errorContainer.withValues(alpha: 0.85);
    final fg = onShelf ? colors.onPrimaryContainer : colors.onErrorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        onShelf ? 'Na prateleira' : 'Fora da prateleira',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
