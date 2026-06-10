import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';

// Modelos temporários para simular os Contextos (CasosContext e AuthContext)
class SimCaso {
  final String id;
  final String moradorNome;
  final String descricao;
  final String status;
  SimCaso(this.id, this.moradorNome, this.descricao, this.status);
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Simulação de Dados
  final String userName = 'Mariana Mendes Lima';
  final String userRole = 'master';

  List<SimCaso> get _casosSimulados => [
    SimCaso('1', 'João Silva', 'Regularização de Terreno', 'triagem'),
    SimCaso('2', 'Maria Oliveira', 'Emissão de Escritura', 'documentacao'),
    SimCaso('3', 'Pedro Santos', 'Análise de Risco', 'processo'),
    SimCaso('4', 'Ana Costa', 'Alvará Concluído', 'finalizado'),
    SimCaso('5', 'Lucas Souza', 'Triagem Inicial', 'triagem'),
  ];

  Map<String, String> get statusLabels => {
    'triagem': 'Triagem',
    'documentacao': 'Documentação',
    'processo': 'Em Processo',
    'finalizado': 'Finalizado',
  };

  Map<String, Color> get _statusColors => {
    'triagem': const Color(0xFF8B95A5),
    'documentacao': const Color(0xFFEAB308),
    'processo': const Color(0xFF3B82F6),
    'finalizado': const Color(0xFF22C55E),
  };

  @override
  Widget build(BuildContext context) {
    // Cálculos de Status
    final filteredCasos = _casosSimulados; // Simulando a filtragem por Role
    
    final andamento = filteredCasos.where((c) => c.status != 'finalizado').length;
    final finalizados = filteredCasos.where((c) => c.status == 'finalizado').length;
    final emTriagem = filteredCasos.where((c) => c.status == 'triagem').length;

    final byStatus = ['triagem', 'documentacao', 'processo', 'finalizado'].map((s) {
      return {
        'name': statusLabels[s]!,
        'value': filteredCasos.where((c) => c.status == s).length,
        'color': _statusColors[s]!,
      };
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da Página
          Text(
            'Dashboard',
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: AppColors.foreground),
          ),
          const SizedBox(height: 4.0),
          Text(
            'Bem-vindo(a), $userName',
            style: TextStyle(fontSize: 14.0, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 24.0),

          // Cards de Estatísticas (Grid)
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 1;
              if (constraints.maxWidth >= 640) crossAxisCount = 2; // sm
              if (constraints.maxWidth >= 1024) crossAxisCount = 4; // lg

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.8,
                children: [
                  _buildStatCard('Total de Casos', filteredCasos.length, Icons.business_center_outlined, AppColors.primary),
                  _buildStatCard('Em Andamento', andamento, Icons.schedule_outlined, AppColors.info),
                  _buildStatCard('Finalizados', finalizados, Icons.check_circle_outline, AppColors.success),
                  _buildStatCard('Em Triagem', emTriagem, Icons.warning_amber_outlined, AppColors.warning),
                ],
              );
            },
          ),
          const SizedBox(height: 24.0),

          // Gráficos
          LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth >= 1024;
              
              Widget barChart = _buildChartCard('Casos por Status', _buildBarChart(byStatus));
              Widget pieChart = _buildChartCard('Distribuição', _buildPieChart(byStatus));

              if (isDesktop) {
                return Row(
                  children: [
                    Expanded(child: barChart),
                    const SizedBox(width: 24.0),
                    Expanded(child: pieChart),
                  ],
                );
              } else {
                return Column(
                  children: [
                    barChart,
                    const SizedBox(height: 24.0),
                    pieChart,
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24.0),

          // Tabela de Casos Recentes
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Casos Recentes',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground),
                      ),
                      TextButton(
                        onPressed: () => context.go('/kanban'),
                        child: Text('Ver todos', style: TextStyle(color: AppColors.accent, fontSize: 14.0)),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppColors.border),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredCasos.take(5).length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final caso = filteredCasos[index];
                    return InkWell(
                      onTap: () => context.go('/caso/${caso.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    caso.moradorNome,
                                    style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.foreground),
                                  ),
                                  Text(
                                    caso.descricao,
                                    style: TextStyle(fontSize: 14.0, color: AppColors.mutedForeground),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: _statusColors[caso.status],
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Text(
                                statusLabels[caso.status]!,
                                style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helpers Visuais
  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 14.0, color: AppColors.mutedForeground)),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8.0)),
                child: Icon(icon, color: Colors.white, size: 18.0),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(value.toString(), style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold, color: AppColors.foreground)),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Container(
      height: 320, // Altura fixa para comportar o título e o gráfico (250 do recharts + padding)
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground)),
          const SizedBox(height: 16.0),
          Expanded(child: chart),
        ],
      ),
    );
  }

  // Gráfico de Barras com FL_Chart
  Widget _buildBarChart(List<Map<String, dynamic>> data) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.map((e) => e['value'] as int).reduce((a, b) => a > b ? a : b).toDouble() + 1,
        barTouchData: BarTouchData(enabled: false), // Desabilita tooltip temporariamente
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(data[value.toInt()]['name'], style: TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
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
              getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
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
                width: 32,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
              ),
            ],
          );
        }),
      ),
    );
  }

  // Gráfico de Pizza com FL_Chart
  Widget _buildPieChart(List<Map<String, dynamic>> data) {
    final validData = data.where((e) => (e['value'] as int) > 0).toList();
    
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 55, // innerRadius
        sections: List.generate(validData.length, (index) {
          return PieChartSectionData(
            color: validData[index]['color'],
            value: (validData[index]['value'] as int).toDouble(),
            title: '${validData[index]['name']}: ${validData[index]['value']}',
            radius: 35, // outerRadius (55 + 35 = 90)
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }),
      ),
    );
  }
}