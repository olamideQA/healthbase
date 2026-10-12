import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_router.dart';

/// A top-level destination in the persistent navigation shell.
class ShellDestination {
  const ShellDestination({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const shellDestinations = <ShellDestination>[
  ShellDestination(
    route: AppRoutes.dashboard,
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  ShellDestination(
    route: AppRoutes.timeline,
    label: 'Timeline',
    icon: Icons.history_outlined,
    selectedIcon: Icons.history,
  ),
  ShellDestination(
    route: AppRoutes.trends,
    label: 'Trends',
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights,
  ),
  ShellDestination(
    route: AppRoutes.medications,
    label: 'Meds',
    icon: Icons.medication_outlined,
    selectedIcon: Icons.medication,
  ),
  ShellDestination(
    route: AppRoutes.profile,
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

/// Width at which the shell switches from a bottom bar to a side rail.
const double kShellRailBreakpoint = 840.0;

/// Persistent app chrome wrapping the five primary tabs.
class AppShell extends StatelessWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  int get _selectedIndex {
    final index = shellDestinations.indexWhere(
      (d) => location == d.route || location.startsWith('${d.route}/'),
    );
    return index < 0 ? 0 : index;
  }

  void _onSelect(BuildContext context, int index) {
    final target = shellDestinations[index].route;
    if (target != location) context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= kShellRailBreakpoint;
    final selected = _selectedIndex;

    if (isWide) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: selected,
                onDestinationSelected: (i) => _onSelect(context, i),
                labelType: NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: FloatingActionButton(
                    heroTag: 'shell-log-rail',
                    tooltip: 'Log',
                    elevation: 0,
                    onPressed: () => showQuickLogSheet(context),
                    child: const Icon(Icons.add),
                  ),
                ),
                destinations: [
                  for (final d in shellDestinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'shell-log-fab',
        onPressed: () => showQuickLogSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Log'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => _onSelect(context, i),
        destinations: [
          for (final d in shellDestinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet offering the fastest ways to record health data.
Future<void> showQuickLogSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      Widget tile({
        required IconData icon,
        required Color color,
        required String title,
        required String subtitle,
        required String route,
      }) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withAlpha(30),
            child: Icon(icon, color: color),
          ),
          title: Text(title, style: AppTypography.titleMedium),
          subtitle: Text(subtitle),
          onTap: () {
            Navigator.of(ctx).pop();
            context.push(route);
          },
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text('What would you like to log?',
                    style: AppTypography.headlineMedium),
              ),
              const SizedBox(height: AppSpacing.sm),
              tile(
                icon: Icons.monitor_heart_outlined,
                color: AppColors.statusUrgent,
                title: 'Record a vital',
                subtitle: 'Heart rate, blood pressure, weight, temperature, glucose',
                route: AppRoutes.addMeasurement,
              ),
              tile(
                icon: Icons.fact_check_outlined,
                color: AppColors.primary500,
                title: '60-second daily check',
                subtitle: 'How you feel, symptoms and medications',
                route: AppRoutes.dailyCheck,
              ),
              tile(
                icon: Icons.medication_outlined,
                color: AppColors.statusSyncing,
                title: 'Add a medication',
                subtitle: 'Track schedules and adherence',
                route: AppRoutes.addMedication,
              ),
            ],
          ),
        ),
      );
    },
  );
}
