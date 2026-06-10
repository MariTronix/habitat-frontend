import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';

// --- Dados Simulados ---
class SimUser {
  final String id, nome, role;
  SimUser(this.id, this.nome, this.role);
}

class SimCaso {
  final String id, status, estagiarioId, coordenadorId;
  final DateTime dataCriacao, dataAtualizacao;
  SimCaso(this.id, this.status, this.estagiarioId, this.coordenadorId, this.dataCriacao, this.dataAtualizacao);
}

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  // Simulação de Estado
  final SimUser currentUser = SimUser('master1', 'Mariana Mendes Lima', 'master');
  bool isLoading = false;

  final List<SimUser> users = [
    SimUser('coord1', 'Lourival', 'coordenador'),
    SimUser('coord2', 'Vladson', 'coordenador'),
    SimUser('est1', 'Hugo', 'estagiario'),
    SimUser('est2', 'Gabriel', 'estagiario'),
  ];

  late List<SimCaso> casos;

  final Map<String, String> statusLabels = {
    'triagem': 'Triagem', 'documentacao': 'Documentação', 'processo': 'Em Processo', 'finalizado': 'Finalizado',
  };

  final Map<String, Color> statusColors = {
    'triagem': const Color(0xFF8B95A5),
    'documentacao': const Color(0xFFEAB308),
    'processo': const Color(0xFF3B82F6),
    'finalizado': const Color(0xFF22C55E),
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    casos = [
      SimCaso('1', 'triagem', 'est1', 'coord1', now.subtract(const Duration(days: 10)), now),
      SimCaso('2', 'documentacao', 'est2', 'coord1', now.subtract(const Duration(days: 15)), now),
      SimCaso('3', 'processo', 'est1', 'coord2', now.subtract(const Duration(days: 20)), now),
      SimCaso('4', 'finalizado', 'est2', 'coord2', now.subtract(const Duration(days: 30)), now.subtract(const Duration(days: 5))),
      SimCaso('5', 'finalizado', 'est1', 'coord1', now.subtract(const Duration(days: 40)), now.subtract(const Duration(days: 10))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Filtros por role
    final filtered = casos.where((c) {
      if (currentUser.role == 'master') return true;
      if (currentUser.role == 'coordenador') return c.coordenadorId == currentUser.id;
      return c.estagiarioId == currentUser.id;
    }).toList();

    // Dados do Gráfico: Por Status
    final byStatus = ['triagem', 'documentacao', 'processo', 'finalizado'].map((s) {
      return {
        'name': statusLabels[s]!,
        'value': filtered.where((c) => c.status == s).length,
        'color': statusColors[s]!,
      };
    }).toList();

    // Dados do Gráfico: Por Estagiário
    final estagiarios = users.where((u) => u.role == 'estagiario').toList();
    final byEstagiario = estagiarios.map((e) {
      return {
        'name': e.nome.split(' ')[0], // Pega o primeiro nome
        'value': filtered.where((c) => c.estagiarioId == e.id).length,
        'color': AppColors.accent,
      };
    }).toList();

    // Dados do Gráfico: Por Coordenador
    final coordenadores = users.where((u) => u.role == 'coordenador').toList();
    final byCoordenador = coordenadores.map((c) {
      return {
        'name': c.nome.split(' ')[0],
        'value': filtered.where((cs) => cs.coordenadorId == c.id).length,
        'color': AppColors.primary,
      };
    }).toList();

    // Métricas Topo
    final finalizados = filtered.where((c) => c.status == 'finalizado').toList();
    int avgDays = 0;
    if (finalizados.isNotEmpty) {
      int totalDays = finalizados.fold(0, (sum, c) {
        return sum + c.dataAtualizacao.difference(c.dataCriacao).inDays; // Inteiro de dias
      });
      avgDays = (totalDays / finalizados.length).round();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Relatórios', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: AppColors.foreground)),
          const SizedBox(height: 4.0),
          Text('Visão analítica dos casos', style: TextStyle(fontSize: 14.0, color: AppColors.mutedForeground)),
          const SizedBox(height: 24.0),

          if (isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text('Carregando dados dos usuários...', style: TextStyle(fontSize: 14.0, color: AppColors.mutedForeground)),
            ),

          // Cards Superiores
          LayoutBuilder(
            builder: (context, constraints) {
              int cols = constraints.maxWidth >= 640 ? 3 : 1;
              return GridView.count(
                crossAxisCount: cols,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.5,
                children: [
                  _buildStatCard('Total de Casos', filtered.length.toString(), null),
                  _buildStatCard('Finalizados', finalizados.length.toString(), AppColors.success),
                  _buildStatCard('Tempo Médio de Resolução', avgDays.toString(), null, suffix: 'dias'),
                ],
              );
            },
          ),
          const SizedBox(height: 24.0),

          // Gráficos Inferiores
          LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth >= 1024; // lg
              
              Widget statusChart = _buildChartCard('Casos por Status', _buildBarChart(byStatus));
              Widget estagiarioChart = _buildChartCard('Casos por Estagiário', _buildBarChart(byEstagiario));
              Widget coordenadorChart = _buildChartCard('Casos por Coordenador', _buildBarChart(byCoordenador));

              if (isDesktop) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: statusChart),
                        const SizedBox(width: 24.0),
                        Expanded(child: estagiarioChart),
                      ],
                    ),
                    const SizedBox(height: 24.0),
                    coordenadorChart, // Ocupa as duas colunas
                  ],
                );
              } else {
                return Column(
                  children: [
                    statusChart,
                    const SizedBox(height: 24.0),
                    estagiarioChart,
                    const SizedBox(height: 24.0),
                    coordenadorChart,
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color? valueColor, {String? suffix}) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12.0), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 14.0, color: AppColors.mutedForeground)),
          const SizedBox(height: 8.0),
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold, color: valueColor ?? AppColors.foreground),
              children: [
                TextSpan(text: value),
                if (suffix != null) TextSpan(text: ' $suffix', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal, color: AppColors.mutedForeground)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12.0), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: AppColors.foreground)),
          const SizedBox(height: 16.0),
          Expanded(child: chart),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return const Center(child: Text('Sem dados'));
    
    double maxY = data.map((e) => e['value'] as int).reduce((a, b) => a > b ? a : b).toDouble() + 1;
    if (maxY < 5) maxY = 5;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(data[value.toInt()]['name'], style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 1, dashArray: [3, 3]),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(data.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: (data[index]['value'] as int).toDouble(),
                color: data[index]['color'],
                width: 40,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
              ),
            ],
          );
        }),
      ),
    );
  }
}