import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final data = state.data;
    final isEmpty = data.customers.isEmpty && data.inventory.isEmpty && data.transactions.isEmpty;

    if (isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.gold, size: 28),
              const SizedBox(height: 12),
              const Text('Nothing recorded yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                'Add your first customer and a product from their sections, or ask another device/user\n'
                'to add some — this view refreshes from the shared server.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => state.refresh(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    double totalRevenue = 0;
    for (final t in data.transactions) {
      totalRevenue += t.amountPaid;
    }
    for (final p in data.payments) {
      totalRevenue += p.amount;
    }

    double totalDebt = 0;
    for (final c in data.customers) {
      totalDebt += state.customerBalance(c.id);
    }

    final lowStock = data.inventory.where((i) => i.stock <= i.lowStockAt).toList();
    final totalExpenses = data.expenses.fold<double>(0, (s, e) => s + e.amount);
    final estimatedProfit = totalRevenue - totalExpenses;

    final now = DateTime.now();
    final buckets = List<double>.filled(8, 0);
    for (final t in data.transactions) {
      final d = DateTime.tryParse(t.date) ?? now;
      final days = now.difference(d).inDays;
      final bucketFromEnd = (days / 7).floor().clamp(0, 7);
      final idx = 7 - bucketFromEnd;
      buckets[idx] += t.amountPaid;
    }

    final Map<String, double> productTotals = {};
    for (final t in data.transactions) {
      for (final it in t.items) {
        productTotals[it.name] = (productTotals[it.name] ?? 0) + it.qty * it.price;
      }
    }
    final topProducts = productTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topFive = topProducts.take(5).toList();

    final recent = [...data.transactions]..sort((a, b) => b.date.compareTo(a.date));
    final recentFive = recent.take(6).toList();

    String customerName(String id) {
      final match = data.customers.where((c) => c.id == id);
      return match.isEmpty ? 'Walk-in' : match.first.name;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('An overview of how the business is doing.', style: TextStyle(color: AppColors.muted, fontSize: 14)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.7,
            children: [
              KpiCard(icon: Icons.people_outline, label: 'Customers', value: '${data.customers.length}'),
              KpiCard(
                  icon: Icons.trending_up,
                  label: 'Revenue collected',
                  value: state.fmt(totalRevenue),
                  accent: AppColors.sage),
              KpiCard(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Outstanding debt',
                  value: state.fmt(totalDebt),
                  accent: AppColors.brick),
              KpiCard(
                  icon: Icons.warning_amber_outlined,
                  label: 'Low stock items',
                  value: '${lowStock.length}',
                  accent: const Color(0xFF8A6115)),
              if (state.isAdmin)
                KpiCard(
                    icon: Icons.savings_outlined,
                    label: 'Estimated profit',
                    value: state.fmt(estimatedProfit),
                    accent: estimatedProfit >= 0 ? AppColors.sage : AppColors.brick),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Revenue collected — last 8 weeks', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (v, meta) {
                              final i = v.toInt();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text('Wk ${i + 1}', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [for (int i = 0; i < 8; i++) FlSpot(i.toDouble(), buckets[i])],
                          isCurved: true,
                          color: AppColors.gold,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(show: true, color: AppColors.gold.withOpacity(0.08)),
                        ),
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
                const Text('Top products by sales value', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 12),
                if (topFive.isEmpty)
                  const Text('No sales yet.', style: TextStyle(color: AppColors.muted, fontSize: 13))
                else
                  ...topFive.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          Expanded(
                            flex: 3,
                            child: Text(e.key, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
                          ),
                          Expanded(
                            flex: 5,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: topFive.first.value == 0 ? 0 : e.value / topFive.first.value,
                                minHeight: 10,
                                backgroundColor: AppColors.paper,
                                valueColor: const AlwaysStoppedAnimation(AppColors.ink),
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
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Recent transactions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
                const Divider(height: 1),
                if (recentFive.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No sales recorded yet.', style: TextStyle(color: AppColors.muted)),
                  ),
                for (final t in recentFive)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(customerName(t.customerId), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                            Text(
                              t.items.map((i) => '${i.qty}× ${i.name}').join(', '),
                              style: const TextStyle(color: AppColors.muted, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(state.fmt(t.total), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 4),
                          StatusChip(status: t.status),
                        ],
                      ),
                    ]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
