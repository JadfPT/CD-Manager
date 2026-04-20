import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_logger.dart';
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
      AppLogger.info('save profile start username=$username', category: 'profile');
      final profile = await _ref
          .read(profileActionsProvider)
          .updateProfile(
            username: username,
            displayName: displayName,
            avatarUrl: avatarUrl,
          );
      AppLogger.info('save profile success', category: 'profile');
      state = const AsyncData(null);
      return profile;
    } catch (error, stackTrace) {
      AppLogger.error(
        'save profile failed',
        category: 'profile',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<String> uploadAvatar({
    required Uint8List fileBytes,
    required String fileExtension,
  }) async {
    AppLogger.info('avatar upload start ext=$fileExtension', category: 'profile');
    try {
      final avatarUrl = await _ref.read(profileActionsProvider).uploadAvatar(
        fileBytes: fileBytes,
            fileExtension: fileExtension,
          );
      AppLogger.info('avatar upload success', category: 'profile');
      return avatarUrl;
    } catch (error, stackTrace) {
      AppLogger.error(
        'avatar upload failed',
        category: 'profile',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
