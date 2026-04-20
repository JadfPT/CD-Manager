import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_section_card.dart';

class ProfileEditSection extends StatelessWidget {
  const ProfileEditSection({
    required this.formKey,
    required this.usernameController,
    required this.displayNameController,
    required this.isSaving,
    required this.onSave,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController displayNameController;
  final bool isSaving;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Editar perfil',
      subtitle: 'Atualiza username e nome de apresentação',
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'nome_utilizador',
                helperText: '3-24 caracteres, letras, números, . _ -',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.alternate_email),
              ),
              textInputAction: TextInputAction.next,
              validator: _validateUsername,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display name',
                hintText: 'Nome visível',
                helperText: '2-40 caracteres',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) async {
                if (!isSaving) {
                  await onSave();
                }
              },
              validator: _validateDisplayName,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSaving ? null : () => onSave(),
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(isSaving ? 'A guardar...' : 'Guardar alterações'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateUsername(String? value) {
    final text = value?.trim() ?? '';
    final pattern = RegExp(r'^[a-zA-Z0-9._-]+$');

    if (text.isEmpty) {
      return 'Indica um username';
    }
    if (text.length < 3) {
      return 'Mínimo de 3 caracteres';
    }
    if (text.length > 24) {
      return 'Máximo de 24 caracteres';
    }
    if (!pattern.hasMatch(text)) {
      return 'Usa apenas letras, números, . _ -';
    }
    return null;
  }

  String? _validateDisplayName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Indica um nome de apresentação';
    }
    if (text.length < 2) {
      return 'Mínimo de 2 caracteres';
    }
    if (text.length > 40) {
      return 'Máximo de 40 caracteres';
    }
    return null;
  }
}
