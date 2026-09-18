import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/user_preferences.dart';
import 'storage_providers.dart';

/// Light/dark/system theme selection.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final userPreferencesProvider = Provider<UserPreferences>(
  (ref) => UserPreferences(),
);

final skipOnboardingProvider = FutureProvider<bool>((ref) async {
  final preferences = ref.watch(userPreferencesProvider);
  return preferences.shouldSkipOnboarding(
    () async => kIsWeb ? 0 : ref.read(photoRepositoryProvider).photoCount(),
  );
});
