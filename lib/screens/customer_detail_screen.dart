import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});
  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _payCtrl = TextEditingController();

  @override
  void dispose() {
    _payCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final data = state.data;
    final matches = data.customers.where((c) => c.id == widget.customerId);
    if (matches.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) Navigator.pop(context);
      });
      return const Scaffold(body: SizedBox());
    }
    final customer = matches.first;
    final bal = state.customerBalance(customer.id);
    final history = data.transactions.where((t) => t.customerId == customer.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(title: Text(customer.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.phone, size: 14, color: AppColors.muted),
              const SizedBox(width: 6),
              Text(customer.phone, style: const TextStyle(color: AppColors.muted, fontSize: 13.5)),
            ]),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Outstanding balance', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      const SizedBox(height: 4),
                      Text(state.fmt(bal),
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: bal > 0 ? AppColors.brick : AppColors.sage)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Record a payment', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      const SizedBox(height: 6),
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _payCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                                hintText: 'Amount', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.sage, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                          onPressed: () async {
                            final amt = double.tryParse(_payCtrl.text);
                            if (amt == null || amt <= 0) return;
                            FocusScope.of(context).unfocus();
                            final err = await state.addPayment(customer.id, amt);
                            if (!context.mounted) return;
                            if (err == null) {
                              _payCtrl.clear();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                            }
                          },
                          child: const Text('Add'),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            const Text('Purchase history', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            if (history.isEmpty) const Text('No purchases yet.', style: TextStyle(color: AppColors.muted)),
            for (int i = 0; i < history.length; i++) ...[
              AppCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(history[i].date, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      StatusChip(status: history[i].status),
                    ]),
                    const SizedBox(height: 4),
                    Text(history[i].items.map((it) => '${it.qty}× ${it.name}').join(', '), style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Total ${state.fmt(history[i].total)} · Paid ${state.fmt(history[i].amountPaid)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (i != history.length - 1) const SizedBox(height: 8),
            ],
            if (state.isAdmin) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () async {
                  final err = await state.deleteCustomer(customer.id);
                  if (!context.mounted) return;
                  if (err == null) {
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                  }
                },
                icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.brick),
                label: const Text('Remove customer', style: TextStyle(color: AppColors.brick)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
