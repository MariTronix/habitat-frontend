import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../src/models.dart';
import '../src/providers.dart';
import '../src/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final casesProvider = context.watch<CasesProvider>();
    final user = auth.user;
    final filteredCasos = casesProvider.casos.where((c) {
      if (user?.role == UserRole.master) return true;
      if (user?.role == UserRole.coordenador) return c.coordenadorId == user?.id;
      return c.estagiarioId == user?.id;
    }).toList();

    final byStatus = CaseStatus.values.map((status) {
      return MapEntry(status, filteredCasos.where((c) => c.status == status).length);
    }).toList();

    final andamento = filteredCasos.where((c) => c.status != CaseStatus.finalizado).length;
    final finalizados = filteredCasos.where((c) => c.status == CaseStatus.finalizado).length;

    final stats = [
      _StatCardData(label: 'Total de Casos', value: filteredCasos.length.toString(), color: HabitatTheme.primary, icon: Icons.work_outline),
      _StatCardData(label: 'Em Andamento', value: andamento.toString(), color: HabitatTheme.info, icon: Icons.schedule),
      _StatCardData(label: 'Finalizados', value: finalizados.toString(), color: HabitatTheme.success, icon: Icons.check_circle_outline),
      _StatCardData(label: 'Em Triagem', value: filteredCasos.where((c) => c.status == CaseStatus.triagem).length.toString(), color: HabitatTheme.warning, icon: Icons.warning_amber_outlined),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Bem-vindo(a), ${user?.nome ?? ''}', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (context, constraints) {
            // Se o espaço for de celular (< 600px), divide a tela para caber 2.
            // O "- 17" serve para dar o desconto seguro do espaçamento (spacing: 16)
            final double cardWidth = constraints.maxWidth < 600
                ? (constraints.maxWidth - 17) / 2
                : 220.0; // Mantém o padrão na Web

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: stats.map((stat) => SizedBox(
                width: cardWidth, // Força a nova largura no card
                child: _StatCard(data: stat),
              )).toList(),
            );
          }),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (context, constraints) {
            // Se for Desktop/Web: Deixa lado a lado com Row e Expanded
            if (constraints.maxWidth > 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _StatusBarChart(byStatus: byStatus)),
                  const SizedBox(width: 16),
                  Expanded(child: _StatusPieChart(byStatus: byStatus)),
                ],
              );
            }
            // Se for Mobile: Empilha com Column SEM usar o Expanded
            else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, // Faz o card ocupar a largura toda
                children: [
                  _StatusBarChart(byStatus: byStatus),
                  const SizedBox(height: 16),
                  _StatusPieChart(byStatus: byStatus),
                ],
              );
            }
          }),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(color: HabitatTheme.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: HabitatTheme.border)),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Casos Recentes', style: Theme.of(context).textTheme.titleMedium),
                      TextButton(onPressed: () => GoRouter.of(context).go('/kanban'), child: const Text('Ver todos')),
                    ],
                  ),
                ),
                const Divider(height: 1, color: HabitatTheme.border),
                Column(
                  children: filteredCasos.take(5).map((c) {
                    return InkWell(
                      onTap: () => GoRouter.of(context).go('/caso/${c.id}'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.morador.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(c.descricao, style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: c.status.color.withOpacity(0.16), borderRadius: BorderRadius.circular(14)),
                              child: Text(c.status.label, style: TextStyle(color: c.status.color, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardData {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCardData({required this.label, required this.value, required this.color, required this.icon});
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: HabitatTheme.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: HabitatTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(data.label, style: Theme.of(context).textTheme.bodyMedium)),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: data.color, borderRadius: BorderRadius.circular(12)),
                child: Icon(data.icon, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(data.value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatusBarChart extends StatelessWidget {
  final List<MapEntry<CaseStatus, int>> byStatus;
  const _StatusBarChart({required this.byStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: HabitatTheme.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: HabitatTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Casos por Status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= byStatus.length) return const SizedBox();
                    return SideTitleWidget(meta: meta, child: Text(byStatus[index].key.label, style: const TextStyle(fontSize: 10)));
                  })),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1),
                borderData: FlBorderData(show: false),
                barGroups: byStatus.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [BarChartRodData(toY: entry.value.value.toDouble(), color: entry.value.key.color, width: 24, borderRadius: BorderRadius.circular(8))],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPieChart extends StatelessWidget {
  final List<MapEntry<CaseStatus, int>> byStatus;
  const _StatusPieChart({required this.byStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: HabitatTheme.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: HabitatTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Distribuição', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: PieChart(
              PieChartData(
                sections: byStatus.where((entry) => entry.value > 0).map((entry) {
                  return PieChartSectionData(
                    color: entry.key.color,
                    value: entry.value.toDouble(),
                    title: '${entry.value}',
                    radius: 60,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  );
                }).toList(),
                sectionsSpace: 4,
                centerSpaceRadius: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
