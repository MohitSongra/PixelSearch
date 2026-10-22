import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const ShellScaffold({super.key, required this.navigationShell});
  static const labels = ['Search', 'Timeline', 'Map', 'Privacy'];
  static const icons = [
    Icons.search_outlined,
    Icons.photo_library_outlined,
    Icons.map_outlined,
    Icons.shield_outlined,
  ];
  static const selectedIcons = [
    Icons.search,
    Icons.photo_library,
    Icons.map,
    Icons.shield,
  ];
  void _select(int i) => navigationShell.goBranch(
    i,
    initialLocation: i == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      body: wide
          ? Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: _select,
                    labelType: NavigationRailLabelType.all,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Icon(
                        Icons.image_search_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    destinations: [
                      for (var i = 0; i < labels.length; i++)
                        NavigationRailDestination(
                          icon: Icon(icons[i]),
                          selectedIcon: Icon(selectedIcons[i]),
                          label: Text(labels[i]),
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: navigationShell),
              ],
            )
          : navigationShell,
      bottomNavigationBar: wide
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: .5),
                  ),
                ),
              ),
              child: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _select,
                destinations: [
                  for (var i = 0; i < labels.length; i++)
                    NavigationDestination(
                      icon: Icon(icons[i]),
                      selectedIcon: Icon(selectedIcons[i]),
                      label: labels[i],
                    ),
                ],
              ),
            ),
    );
  }
}
