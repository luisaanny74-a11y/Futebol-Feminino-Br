import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/settings_dialog.dart';
import 'dashboard_screen.dart';
import 'equipes_screen.dart';
import 'jogadores_screen.dart';
import 'partidas_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _started = false;

  static const _destinations = [
    (Icons.dashboard_outlined, Icons.dashboard, 'Início'),
    (Icons.groups_outlined, Icons.groups, 'Equipes'),
    (Icons.person_outline, Icons.person, 'Jogadoras'),
    (Icons.sports_soccer_outlined, Icons.sports_soccer, 'Partidas'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      AppScope.of(context).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.rail;

    Widget body;
    if (state.error != null && _index != 0) {
      body = ErrorView(
        message: state.error!,
        onRetry: state.refresh,
        onSettings: () => showSettingsDialog(context),
      );
    } else {
      body = switch (_index) {
        0 => DashboardScreen(onNavigate: (i) => setState(() => _index = i)),
        1 => const EquipesScreen(),
        2 => const JogadoresScreen(),
        _ => const PartidasScreen(),
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_destinations[_index].$3,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (state.loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.lime)),
              ),
            ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: state.refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Configurações',
            onPressed: () => showSettingsDialog(context),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                      icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: Text(d.$3)),
              ],
            ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Breakpoints.content),
                child: body,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                      icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: d.$3),
              ],
            ),
    );
  }
}
