import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import './router.dart';

class CDManagerApp extends ConsumerWidget {
  const CDManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'CD Manager',
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
