import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../../auth/application/auth_providers.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final currentProfileUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthSuccess) {
    return authState.user.id;
  }
  return null;
});

final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final userId = ref.watch(currentProfileUserIdProvider);
  if (userId == null) {
    return null;
  }

  final repository = ref.watch(profileRepositoryProvider);
  return repository.getProfileById(userId);
});

final profileActionsProvider = Provider<ProfileActions>((ref) {
  return ProfileActions(ref);
});

class ProfileActions {
  const ProfileActions(this._ref);

  final Ref _ref;

  Future<Profile> updateProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
  }) async {
    final repository = _ref.read(profileRepositoryProvider);
    final profile = await repository.updateCurrentUserProfile(
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
    _ref.invalidate(currentProfileProvider);
    return profile;
  }

  Future<String> uploadAvatar({
    required Uint8List fileBytes,
    required String fileExtension,
  }) async {
    final repository = _ref.read(profileRepositoryProvider);
    final avatarUrl = await repository.uploadAvatarForCurrentUser(
      fileBytes: fileBytes,
      fileExtension: fileExtension,
    );
    _ref.invalidate(currentProfileProvider);
    return avatarUrl;
  }
}
