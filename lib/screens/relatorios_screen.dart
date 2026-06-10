import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../src/models.dart';
import '../src/providers.dart';
import '../src/app_theme.dart';

class RelatoriosScreen extends StatelessWidget {
  const RelatoriosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final casesProvider = context.watch<CasesProvider>();
    final user = auth.user;
    final filtered = casesProvider.casos.where((c) {
      if (user?.role == UserRole.master) return true;
      if (user?.role == UserRole.coordenador) return c.coordenadorId == user?.id;
      return c.estagiarioId == user?.id;
    }).toList();

    final byStatus = CaseStatus.values.map((status) => MapEntry(status, filtered.where((c) => c.status == status).length)).toList();
    final estagiarios = auth.users.where((u) => u.role == UserRole.estagiario).toList();
    final byEstagiario = estagiarios.map((e) => MapEntry(e.nome.split(' ').first, filtered.where((c) => c.estagiarioId == e.id).length)).toList();
    final coordenadores = auth.users.where((u) => u.role == UserRole.coordenador).toList();
    final byCoordenador = coordenadores.map((e) => MapEntry(e.nome.split(' ').first, filtered.where((c) => c.coordenadorId == e.id).length)).toList();
    final finalizados = filtered.where((c) => c.status == CaseStatus.finalizado).toList();
    final avgDays = finalizados.isEmpty
        ? 0
        : (finalizados.map((c) {
            final created = DateTime.tryParse(c.dataCriacao) ?? DateTime.now();
            final updated = DateTime.tryParse(c.dataAtualizacao) ?? created;
            return updated.difference(created).inDays;
          }).reduce((a, b) => a + b) ~/ finalizados.length);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Relatórios', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text('Visão analítica dos casos', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        Wrap(spacing: 16, runSpacing: 16, children: [
          _SummaryCard(title: 'Total de Casos', value: filtered.length.toString()),
          _SummaryCard(title: 'Finalizados', value: finalizados.length.toString(), color: HabitatTheme.success),
          _SummaryCard(title: 'Tempo Médio de Resolução', value: '$avgDays dias'),
        ]),
        const SizedBox(height: 24),
        _ReportChart(title: 'Casos por Status', data: byStatus.map((entry) => _ChartItem(entry.key.label, entry.value, entry.key.color)).toList()),
        const SizedBox(height: 20),
        _ReportChart(title: 'Casos por Estagiário', data: byEstagiario.map((entry) => _ChartItem(entry.key, entry.value, HabitatTheme.accent)).toList()),
        const SizedBox(height: 20),
        _ReportChart(title: 'Casos por Coordenador', data: byCoordenador.map((entry) => _ChartItem(entry.key, entry.value, HabitatTheme.primary)).toList()),
      ]),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _SummaryCard({required this.title, required this.value, this.color = HabitatTheme.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: HabitatTheme.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: HabitatTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}

class _ReportChart extends StatelessWidget {
  final String title;
  final List<_ChartItem> data;
  const _ReportChart({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: HabitatTheme.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: HabitatTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) return const SizedBox();
                  return SideTitleWidget(meta: meta, child: Text(data[index].label, style: const TextStyle(fontSize: 10)));
                })),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true, horizontalInterval: 1),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((entry) {
                return BarChartGroupData(x: entry.key, barRods: [BarChartRodData(toY: entry.value.value.toDouble(), color: entry.value.color, width: 24, borderRadius: BorderRadius.circular(8))]);
              }).toList(),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ChartItem {
  final String label;
  final int value;
  final Color color;
  const _ChartItem(this.label, this.value, this.color);
}
