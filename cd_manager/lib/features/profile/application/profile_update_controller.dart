import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/profile.dart';
import 'profile_providers.dart';

final profileUpdateControllerProvider =
    StateNotifierProvider<ProfileUpdateController, AsyncValue<void>>(
      (ref) => ProfileUpdateController(ref),
    );

class ProfileUpdateController extends StateNotifier<AsyncValue<void>> {
  ProfileUpdateController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<Profile> save({
    required String username,
    required String displayName,
    required String avatarUrl,
  }) async {
    state = const AsyncLoading();

    try {
      final profile = await _ref
          .read(profileActionsProvider)
          .updateProfile(
            username: username,
            displayName: displayName,
            avatarUrl: avatarUrl,
          );
      state = const AsyncData(null);
      return profile;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
