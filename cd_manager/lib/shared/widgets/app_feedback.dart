import 'package:flutter/material.dart';

enum FeedbackType { success, error, info }

class AppFeedback {
  static void success(BuildContext context, String message) {
    _show(context, message: message, type: FeedbackType.success);
  }

  static void error(BuildContext context, String message) {
    _show(context, message: message, type: FeedbackType.error);
  }

  static void info(BuildContext context, String message) {
    _show(context, message: message, type: FeedbackType.info);
  }

  static void _show(
    BuildContext context, {
    required String message,
    required FeedbackType type,
  }) {
    final colors = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);

    final icon = switch (type) {
      FeedbackType.success => Icons.check_circle_outline,
      FeedbackType.error => Icons.error_outline,
      FeedbackType.info => Icons.info_outline,
    };

    final accentColor = switch (type) {
      FeedbackType.success => Colors.greenAccent.shade200,
      FeedbackType.error => colors.error,
      FeedbackType.info => colors.primary,
    };

    final background = switch (type) {
      FeedbackType.success => const Color(0xFF163323),
      FeedbackType.error => const Color(0xFF3A1D22),
      FeedbackType.info => const Color(0xFF1D2733),
    };

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        elevation: 0,
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: accentColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
