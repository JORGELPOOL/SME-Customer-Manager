import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});
  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  String copiedId = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final data = state.data;

    final debtors = data.customers.map((c) => MapEntry(c, state.customerBalance(c.id))).where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String message(String name, double balance) =>
        'Hello $name, this is a friendly reminder from ${data.business.name} that you have an outstanding balance of ${state.fmt(balance)}. Kindly settle at your earliest convenience. Thank you!';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customers with an outstanding balance, sorted by amount owed.', style: TextStyle(color: AppColors.muted, fontSize: 14)),
          const SizedBox(height: 14),
          Expanded(
            child: debtors.isEmpty
                ? const Center(child: Text('No outstanding balances — everyone is paid up.', style: TextStyle(color: AppColors.muted)))
                : ListView.separated(
                    itemCount: debtors.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final c = debtors[i].key;
                      final bal = debtors[i].value;
                      final msg = message(c.name, bal);
                      return AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                                    Text(c.phone + (c.lastReminded != null ? ' · last reminded ${c.lastReminded}' : ''),
                                        style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                                  ],
                                ),
                              ),
                              Text(state.fmt(bal), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.brick, fontSize: 16)),
                            ]),
                            const SizedBox(height: 8),
                            Text(msg, style: const TextStyle(fontSize: 13, color: Color(0xFF5A5849))),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: copiedId == c.id ? AppColors.sage : AppColors.ink),
                                onPressed: () async {
                                  await Clipboard.setData(ClipboardData(text: msg));
                                  state.markReminded(c.id);
                                  setState(() => copiedId = c.id);
                                  Future.delayed(const Duration(milliseconds: 1800), () {
                                    if (mounted) setState(() => copiedId = '');
                                  });
                                },
                                icon: Icon(copiedId == c.id ? Icons.check : Icons.copy, size: 15),
                                label: Text(copiedId == c.id ? 'Copied' : 'Copy reminder'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
