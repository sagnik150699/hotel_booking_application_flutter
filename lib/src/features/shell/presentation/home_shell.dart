import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../../../shared/widgets/fade_indexed_stack.dart';
import '../../booking/presentation/pages/trips_page.dart';
import '../../hotels/presentation/pages/explore_page.dart';
import '../../hotels/presentation/pages/saved_hotels_page.dart';
import '../application/shell_controller.dart';

/// Top-level navigation. A bottom [NavigationBar] on phones, a
/// [NavigationRail] on tablets and an extended rail on desktop and wide web
/// windows. Tab pages keep their state across switches.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  static const List<Widget> _pages = <Widget>[
    ExplorePage(),
    SavedHotelsPage(),
    TripsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        deps.shell,
        deps.saved,
        deps.bookings,
      ]),
      builder: (context, _) {
        final index = deps.shell.index;
        final savedCount = deps.saved.count;
        final tripCount = deps.bookings.upcoming.length;

        return ResponsiveBuilder(
          builder: (context, size) {
            final body = FadeIndexedStack(index: index, children: _pages);

            if (size.isMobile) {
              return Scaffold(
                body: body,
                bottomNavigationBar: NavigationBar(
                  selectedIndex: index,
                  onDestinationSelected: deps.shell.selectIndex,
                  destinations: <Widget>[
                    const NavigationDestination(
                      icon: Icon(Icons.explore_outlined),
                      selectedIcon: Icon(Icons.explore),
                      label: 'Explore',
                    ),
                    NavigationDestination(
                      icon: _CountBadge(
                        count: savedCount,
                        child: const Icon(Icons.favorite_border),
                      ),
                      selectedIcon: _CountBadge(
                        count: savedCount,
                        child: const Icon(Icons.favorite),
                      ),
                      label: 'Saved',
                    ),
                    NavigationDestination(
                      icon: _CountBadge(
                        count: tripCount,
                        child: const Icon(Icons.luggage_outlined),
                      ),
                      selectedIcon: _CountBadge(
                        count: tripCount,
                        child: const Icon(Icons.luggage),
                      ),
                      label: 'Trips',
                    ),
                  ],
                ),
              );
            }

            final extended = size.isDesktop;
            return Scaffold(
              body: Row(
                children: <Widget>[
                  NavigationRail(
                    extended: extended,
                    minExtendedWidth: 240,
                    selectedIndex: index,
                    onDestinationSelected: deps.shell.selectIndex,
                    labelType: extended ? NavigationRailLabelType.none : null,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                      child: extended
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                BrandMark(size: 36),
                                SizedBox(width: AppSpacing.md),
                                Flexible(
                                  child: Text(
                                    'Hotel Booking',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const BrandMark(size: 36),
                    ),
                    destinations: <NavigationRailDestination>[
                      const NavigationRailDestination(
                        icon: Icon(Icons.explore_outlined),
                        selectedIcon: Icon(Icons.explore),
                        label: Text('Explore'),
                      ),
                      NavigationRailDestination(
                        icon: _CountBadge(
                          count: savedCount,
                          child: const Icon(Icons.favorite_border),
                        ),
                        selectedIcon: _CountBadge(
                          count: savedCount,
                          child: const Icon(Icons.favorite),
                        ),
                        label: const Text('Saved'),
                      ),
                      NavigationRailDestination(
                        icon: _CountBadge(
                          count: tripCount,
                          child: const Icon(Icons.luggage_outlined),
                        ),
                        selectedIcon: _CountBadge(
                          count: tripCount,
                          child: const Icon(Icons.luggage),
                        ),
                        label: const Text('Trips'),
                      ),
                    ],
                  ),
                  const VerticalDivider(),
                  Expanded(child: body),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Badge.count(count: count, isLabelVisible: count > 0, child: child);
  }
}

/// Exposes the size class helpers to pages that need to know whether they are
/// hosted behind a bottom bar or a rail.
extension ShellLayoutContext on BuildContext {
  ScreenSize get screenSize => Breakpoints.of(this);
}

/// Convenience for pages that switch tabs (e.g. an empty state's action).
extension ShellNavigation on BuildContext {
  void showShellTab(ShellTab tab) => AppScope.of(this).shell.select(tab);
}
