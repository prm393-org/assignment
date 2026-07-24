import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/widgets/notched_bottom_nav_bar.dart';
import 'package:chuoi_xanh_viet/core/widgets/shell_navigation_models.dart';

export 'package:chuoi_xanh_viet/core/widgets/shell_navigation_models.dart';

class RoleShell extends StatelessWidget {
  const RoleShell({
    super.key,
    required this.navigationShell,
    required this.destinations,
    this.centerAction,
    this.centerIndex = 2,
  });

  final StatefulNavigationShell navigationShell;
  final List<ShellDestination> destinations;
  final ShellCenterAction? centerAction;
  final int centerIndex;

  int get _branchCount => destinations.length;

  int _navIndexForBranch(int branchIndex) {
    final center = centerAction;
    if (center == null) return branchIndex;
    if (branchIndex >= centerIndex) return branchIndex + 1;
    return branchIndex;
  }

  int? _branchForNavIndex(int navIndex) {
    final center = centerAction;
    if (center == null) return navIndex;
    if (navIndex == centerIndex) return null;
    if (navIndex > centerIndex) return navIndex - 1;
    return navIndex;
  }

  void _onNavTap(BuildContext context, int navIndex) {
    final center = centerAction;
    if (center != null && navIndex == centerIndex) {
      context.push(center.path);
      return;
    }
    final branch = _branchForNavIndex(navIndex);
    if (branch == null) return;
    navigationShell.goBranch(
      branch,
      initialLocation: branch == navigationShell.currentIndex,
    );
  }

  List<NotchedNavItem> _sideItems(
    BuildContext context, {
    required int selectedNavIndex,
    required int start,
    required int end,
    required int step,
  }) {
    final items = <NotchedNavItem>[];
    for (var i = start; step > 0 ? i < end : i > end; i += step) {
      final branch = _branchForNavIndex(i);
      if (branch == null) continue;
      items.add(
        NotchedNavItem(
          destination: destinations[branch],
          selected: i == selectedNavIndex,
          onTap: () => _onNavTap(context, i),
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final center = centerAction;
    final selectedNavIndex = _navIndexForBranch(navigationShell.currentIndex);
    final navCount = center == null ? _branchCount : _branchCount + 1;

    return Scaffold(
      extendBody: center != null,
      body: navigationShell,
      bottomNavigationBar: center == null
          ? NavigationBar(
              selectedIndex: selectedNavIndex,
              onDestinationSelected: (index) => _onNavTap(context, index),
              destinations: [
                for (final d in destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon ?? d.icon),
                    label: d.label,
                  ),
              ],
            )
          : SafeArea(
              top: false,
              child: NotchedBottomNavBar(
                leftItems: _sideItems(
                  context,
                  selectedNavIndex: selectedNavIndex,
                  start: 0,
                  end: centerIndex,
                  step: 1,
                ),
                rightItems: _sideItems(
                  context,
                  selectedNavIndex: selectedNavIndex,
                  start: centerIndex + 1,
                  end: navCount,
                  step: 1,
                ),
                centerAction: center,
                onCenterTap: () => _onNavTap(context, centerIndex),
              ),
            ),
    );
  }
}
