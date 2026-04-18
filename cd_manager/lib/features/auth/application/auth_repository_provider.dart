import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
