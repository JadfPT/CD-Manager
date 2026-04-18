class AppException implements Exception {
  final String message;
  final String? code;

  AppException({
    required this.message,
    this.code,
  });

  @override
  String toString() => message;
}

String handleError(dynamic error) {
  if (error is AppException) {
    return error.message;
  }

  final message = error.toString();

  String extractSupabaseMessage(String value) {
    final match = RegExp(r'message:\s*([^,\)]+)').firstMatch(value);
    if (match != null) {
      return match.group(1)?.trim() ?? value;
    }
    return value;
  }

  final normalized = extractSupabaseMessage(message);

  if (normalized.contains('Invalid login credentials')) {
    return 'Email ou password inválidos';
  }

  if (normalized.contains('User already registered')) {
    return 'Este email já está registado';
  }

  if (normalized.contains('Password should be at least')) {
    return 'A password deve ter pelo menos 6 caracteres';
  }

  if (normalized.contains('Email not confirmed')) {
    return 'Confirma o teu email antes de iniciar sessão';
  }

  if (normalized.contains('refresh_token_not_found') ||
      normalized.contains('Invalid Refresh Token') ||
      normalized.contains('JWT expired')) {
    return 'A tua sessão expirou. Inicia sessão novamente';
  }

  if (normalized.contains('connection') ||
      normalized.contains('SocketException') ||
      normalized.contains('Failed host lookup')) {
    return 'Erro de conexão. Verifica a tua internet';
  }

  if (normalized.contains('Invalid argument(s)') ||
      normalized.contains('Dados inválidos')) {
    return 'Sessão local inválida. Tenta novamente (ou reinicia a app)';
  }

  if (normalized.isNotEmpty && normalized != message) {
    return normalized;
  }

  return 'Ocorreu um erro. Tenta novamente';
}
