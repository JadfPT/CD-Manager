class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'O email é obrigatório';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Introduz um email válido';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'A password é obrigatória';
    }

    if (value.length < 6) {
      return 'A password deve ter pelo menos 6 caracteres';
    }

    return null;
  }

  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'A password é obrigatória';
    }

    return null;
  }

  static String? validatePasswordConfirm(String? password, String? confirm) {
    if (confirm == null || confirm.isEmpty) {
      return 'Confirma a password';
    }

    if (password != confirm) {
      return 'As passwords não correspondem';
    }

    return null;
  }
}
