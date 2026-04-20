import 'package:flutter/material.dart';
import '../../core/utils/app_logger.dart';
import '../widgets/app_feedback.dart';

class UiActionExecutor {
  static Future<bool> run(
    BuildContext context, {
    required Future<void> Function() action,
    required String actionName,
    String? successMessage,
    String? errorMessage,
    String logCategory = 'ui.action',
  }) async {
    try {
      AppLogger.info('start: $actionName', category: logCategory);
      await action();
      if (successMessage != null && context.mounted) {
        AppFeedback.success(context, successMessage);
      }
      AppLogger.info('success: $actionName', category: logCategory);
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        'failed: $actionName',
        category: logCategory,
        error: error,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        AppFeedback.error(context, errorMessage ?? 'Falha ao executar ação: $error');
      }
      return false;
    }
  }
}
