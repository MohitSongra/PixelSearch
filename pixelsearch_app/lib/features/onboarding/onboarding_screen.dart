import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              const Spacer(),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.tertiary],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.search, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 28),
              Text('Search your\nmemories',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: -1,
                      )),
              const SizedBox(height: 16),
              Text(
                'Find any photo with natural language — “beach at sunset”, '
                '“my dog”, “birthday cake”. Everything runs on your device. '
                'Nothing is uploaded.',
                style: TextStyle(
                    color: scheme.onSurfaceVariant, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 28),
              _point(context, Icons.lock_outline, 'Private by design',
                  'Indexing and search happen fully offline.'),
              _point(context, Icons.bolt_outlined, 'Fast semantic search',
                  'Results in under two seconds.'),
              _point(context, Icons.auto_awesome_outlined, 'Optional cloud extras',
                  'AI captions & assistant — only with your consent.'),
              const Spacer(),
              if (indexingSupported)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    // Kick off the real pipeline and move on immediately — a full
                    // gallery takes minutes, and Search shows live progress.
                    onPressed: () {
                      unawaited(
                          ref.read(indexingControllerProvider.notifier).start());
                      context.go('/home/search');
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Index my photos'),
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/home/search'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                      indexingSupported ? 'Not now' : 'Continue'),
                ),
              ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _point(BuildContext context, IconData icon, String title, String sub) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(sub,
                    style: TextStyle(
                        color: scheme.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
