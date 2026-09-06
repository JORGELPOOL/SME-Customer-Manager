import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../models.dart';
import '../utils.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  void _openForm(BuildContext context, AppState state) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String category = expenseCategories.first;
    String date = todayIso();
    String error = '';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add expense'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                value: category,
                items: expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => category = v ?? category),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
                autofocus: true,
              ),
              const SizedBox(height: 10),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Note (optional)')),
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.tryParse(date) ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (picked != null) {
                    setState(() => date =
                        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date'),
                  child: Text(date),
                ),
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error, style: const TextStyle(color: AppColors.brick, fontSize: 12.5)),
                ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final amt = double.tryParse(amountCtrl.text);
                      if (amt == null || amt <= 0) return;
                      setState(() => saving = true);
                      final err = await state.addExpense(category: category, amount: amt, date: date, note: noteCtrl.text.trim());
                      if (err != null) {
                        setState(() {
                          saving = false;
                          error = err;
                        });
                        return;
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: Text(saving ? 'Saving…' : 'Save expense'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final data = state.data;
    final expenses = [...data.expenses]..sort((a, b) => b.date.compareTo(a.date));
    final total = data.expenses.fold<double>(0, (s, e) => s + e.amount);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, state),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Track day-to-day business costs.', style: TextStyle(color: AppColors.muted, fontSize: 14)),
            const SizedBox(height: 12),
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total recorded', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                  Text(state.fmt(total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.brick)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: expenses.isEmpty
                  ? const Center(child: Text('No expenses recorded yet.', style: TextStyle(color: AppColors.muted)))
                  : ListView.separated(
                      itemCount: expenses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final e = expenses[i];
                        return AppCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(e.category, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              [e.date, if (e.note.isNotEmpty) e.note].join(' · '),
                              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                            ),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(state.fmt(e.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.brick),
                                onPressed: () async {
                                  final err = await state.deleteExpense(e.id);
                                  if (err != null && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                  }
                                },
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
