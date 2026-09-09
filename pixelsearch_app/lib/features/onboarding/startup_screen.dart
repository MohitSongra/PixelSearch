import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';
import 'onboarding_screen.dart';

class StartupScreen extends ConsumerWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(skipOnboardingProvider)
        .when(
          data: (skip) {
            if (!skip) return const OnboardingScreen();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/home/search');
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not open your saved library.'),
                  TextButton.icon(
                    onPressed: () => ref.invalidate(skipOnboardingProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
  }
}
