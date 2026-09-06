import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final data = state.data;

    double totalRevenue = 0;
    for (final t in data.transactions) {
      totalRevenue += t.amountPaid;
    }
    for (final p in data.payments) {
      totalRevenue += p.amount;
    }
    final totalExpenses = data.expenses.fold<double>(0, (s, e) => s + e.amount);
    final estimatedProfit = totalRevenue - totalExpenses;

    final now = DateTime.now();
    final revenueBuckets = List<double>.filled(8, 0);
    for (final t in data.transactions) {
      final d = DateTime.tryParse(t.date) ?? now;
      final days = now.difference(d).inDays;
      final idx = 7 - (days / 7).floor().clamp(0, 7);
      revenueBuckets[idx] += t.amountPaid;
    }
    final expenseBuckets = List<double>.filled(8, 0);
    for (final e in data.expenses) {
      final d = DateTime.tryParse(e.date) ?? now;
      final days = now.difference(d).inDays;
      final idx = 7 - (days / 7).floor().clamp(0, 7);
      expenseBuckets[idx] += e.amount;
    }

    final Map<String, double> byCategory = {};
    for (final e in data.expenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }
    final categoryEntries = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final maxBar = [
      ...revenueBuckets,
      ...expenseBuckets,
    ].fold<double>(1, (m, v) => v > m ? v : m);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A simplified estimate — revenue collected minus expenses recorded. It does not account for unsold stock value.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: KpiCard(icon: Icons.trending_up, label: 'Revenue collected', value: state.fmt(totalRevenue), accent: AppColors.sage)),
            const SizedBox(width: 12),
            Expanded(child: KpiCard(icon: Icons.receipt_long_outlined, label: 'Expenses', value: state.fmt(totalExpenses), accent: AppColors.brick)),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                icon: Icons.savings_outlined,
                label: 'Estimated profit',
                value: state.fmt(estimatedProfit),
                accent: estimatedProfit >= 0 ? AppColors.sage : AppColors.brick,
              ),
            ),
          ]),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Revenue vs expenses — last 8 weeks', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 6),
                Row(children: [
                  _legendDot(AppColors.sage, 'Revenue'),
                  const SizedBox(width: 14),
                  _legendDot(AppColors.brick, 'Expenses'),
                ]),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      maxY: maxBar * 1.15,
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (v, meta) => Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text('Wk ${v.toInt() + 1}', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                            ),
                          ),
                        ),
                      ),
                      barGroups: [
                        for (int i = 0; i < 8; i++)
                          BarChartGroupData(x: i, barRods: [
                            BarChartRodData(toY: revenueBuckets[i], color: AppColors.sage, width: 7, borderRadius: BorderRadius.circular(2)),
                            BarChartRodData(toY: expenseBuckets[i], color: AppColors.brick, width: 7, borderRadius: BorderRadius.circular(2)),
                          ], barsSpace: 3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Expenses by category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 12),
                if (categoryEntries.isEmpty)
                  const Text('No expenses recorded yet.', style: TextStyle(color: AppColors.muted, fontSize: 13))
                else
                  ...categoryEntries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          Expanded(flex: 3, child: Text(e.key, style: const TextStyle(fontSize: 12.5))),
                          Expanded(
                            flex: 5,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: categoryEntries.first.value == 0 ? 0 : e.value / categoryEntries.first.value,
                                minHeight: 10,
                                backgroundColor: AppColors.paper,
                                valueColor: const AlwaysStoppedAnimation(AppColors.brick),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(state.fmt(e.value), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
    ]);
  }
}
