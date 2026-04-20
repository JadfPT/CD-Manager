import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_section_card.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: title,
      subtitle: subtitle,
      child: child,
    );
  }
}
