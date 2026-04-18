import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getCurrentUserProfile();
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
}
