import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/config/supabase_config.dart';

bool _isLikelyPlaceholder(String value) {
  final lower = value.toLowerCase();
  return lower.contains('seu-projeto') ||
      lower.contains('sua-anon-key') ||
      lower.contains('your_') ||
      lower.contains('example');
}

bool _isValidSupabaseUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null) return false;
  return uri.scheme == 'https' && uri.host.contains('supabase.co');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'Faltam SUPABASE_URL e/ou SUPABASE_ANON_KEY no ficheiro .env',
    );
  }

  if (!_isValidSupabaseUrl(supabaseUrl) || _isLikelyPlaceholder(supabaseUrl)) {
    throw Exception(
      'SUPABASE_URL inválido no .env. Usa a URL real do projeto Supabase (https://<project-ref>.supabase.co).',
    );
  }

  if (_isLikelyPlaceholder(supabaseAnonKey) || supabaseAnonKey.length < 20) {
    throw Exception(
      'SUPABASE_ANON_KEY inválido no .env. Usa a chave pública real em Settings > API do Supabase.',
    );
  }
  
  await SupabaseConfig.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: CDManagerApp(),
    ),
  );
}