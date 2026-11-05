import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/settings_dialog.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onNavigate});

  /// Índices: 1 = Equipes, 2 = Jogadoras, 3 = Partidas.
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final wide = MediaQuery.sizeOf(context).width >= 600;

    final stats = <_Stat>[
      _Stat('Equipes', '${state.equipes.length}', Icons.groups_rounded, 1),
      _Stat('Jogadoras', '${state.jogadores.length}', Icons.person_rounded, 2),
      _Stat('Partidas', '${state.partidas.length}', Icons.sports_soccer_rounded, 3),
      _Stat('Gols marcados', '${state.totalGols}', Icons.emoji_events_rounded, 3),
    ];
    final recentes = state.partidas.reversed.take(3).toList();

    return RefreshIndicator(
      color: AppColors.lime,
      onRefresh: state.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Hero: imagem em tela cheia com chamada, no estilo da referência.
          ClipPath(
            clipper: ShapeBorderClipper(shape: chamfer(radius: 20)),
            child: SizedBox(
              height: wide ? 300 : 230,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ResponsiveAsset(
                    'hero_painting',
                    alignment: Alignment(0, -0.35),
                    semanticLabel: 'Jogadora chutando a bola ao pôr do sol',
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xF00A0D0B), Color(0x000A0D0B)],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('FUTEBOL\nFEMININO BR',
                            style: text.headlineMedium?.copyWith(
                                color: AppColors.lime,
                                fontWeight: FontWeight.w900,
                                height: 1.05)),
                        const SizedBox(height: 6),
                        Text('Gerencie equipes, jogadoras e partidas.',
                            style: text.bodyMedium
                                ?.copyWith(color: AppColors.text)),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: () => onNavigate(3),
                          child: const Text('Ver partidas'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Dashboard geral', style: text.titleLarge),
          Text('Resumo das informações do campeonato',
              style: text.bodySmall?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          if (state.loading && !state.loaded)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: AppColors.lime)),
            )
          else if (state.error != null && state.equipes.isEmpty && state.partidas.isEmpty)
            ErrorView(
                message: state.error!,
                onRetry: state.refresh,
                onSettings: () => showSettingsDialog(context))
          else ...[
            LayoutBuilder(builder: (context, box) {
              final cols = box.maxWidth >= 900 ? 4 : 2;
              const gap = 10.0;
              final w = (box.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final s in stats)
                    SizedBox(width: w, child: _StatCard(stat: s, onTap: () => onNavigate(s.target))),
                ],
              );
            }),
            const SizedBox(height: 24),
            Text('Últimas partidas', style: text.titleMedium),
            const SizedBox(height: 10),
            if (recentes.isEmpty)
              const EmptyView(message: 'Nenhuma partida cadastrada ainda.')
            else
              for (final p in recentes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: NeonCard(
                    onTap: () => onNavigate(3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(state.nomeCasa(p),
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _Score(p),
                        ),
                        Expanded(
                          child: Text(state.nomeVisitante(p),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, this.icon, this.target);
  final String label;
  final String value;
  final IconData icon;
  final int target;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat, required this.onTap});
  final _Stat stat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: ShapeDecoration(
                color: AppColors.lime, shape: chamfer(radius: 10, border: AppColors.lime)),
            child: Icon(stat.icon, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                Text(stat.value,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Placar no formato "2 x 1", em destaque.
class _Score extends StatelessWidget {
  const _Score(this.p);
  final Partida p;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: ShapeDecoration(
            color: AppColors.lime, shape: chamfer(radius: 8, border: AppColors.lime)),
        child: Text('${p.placarCasa} x ${p.placarVisitante}',
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.w800)),
      );
}
