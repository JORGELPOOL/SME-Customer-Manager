import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'customer_detail_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String query = '';

  void _openAddDialog(BuildContext context, AppState state) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String error = '';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Add customer'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full name'), autofocus: true),
            const SizedBox(height: 12),
            TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone number'),
                keyboardType: TextInputType.phone),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error, style: const TextStyle(color: AppColors.brick, fontSize: 12.5)),
              ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;
                      setInner(() => saving = true);
                      final err = await state.addCustomer(nameCtrl.text.trim(), phoneCtrl.text.trim());
                      if (err != null) {
                        setInner(() {
                          saving = false;
                          error = err;
                        });
                        return;
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: Text(saving ? 'Saving…' : 'Save'),
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
    final filtered = data.customers
        .where((c) => c.name.toLowerCase().contains(query.toLowerCase()) || c.phone.contains(query))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddDialog(context, state),
        icon: const Icon(Icons.add),
        label: const Text('Add customer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${data.customers.length} customers on record.', style: const TextStyle(color: AppColors.muted, fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(hintText: 'Search name or phone', prefixIcon: Icon(Icons.search, size: 20)),
              onChanged: (v) => setState(() => query = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No customers found.', style: TextStyle(color: AppColors.muted)))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final c = filtered[i];
                        final bal = state.customerBalance(c.id);
                        final count = data.transactions.where((t) => t.customerId == c.id).length;
                        return AppCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${c.phone} · $count purchase${count == 1 ? '' : 's'}',
                                style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(state.fmt(bal),
                                  style: TextStyle(fontWeight: FontWeight.w700, color: bal > 0 ? AppColors.brick : AppColors.sage)),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
                            ]),
                            onTap: () => Navigator.push(
                                context, MaterialPageRoute(builder: (_) => CustomerDetailScreen(customerId: c.id))),
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
