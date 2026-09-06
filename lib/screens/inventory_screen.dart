import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../models.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  void _openForm(BuildContext context, AppState state, {Product? editing}) {
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final skuCtrl = TextEditingController(text: editing?.sku ?? '');
    final priceCtrl = TextEditingController(text: editing != null ? editing.price.toString() : '');
    final stockCtrl = TextEditingController(text: editing != null ? editing.stock.toString() : '');
    final lowCtrl = TextEditingController(text: editing != null ? editing.lowStockAt.toString() : '5');
    String error = '';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: Text(editing != null ? 'Edit product' : 'Add product'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product name'), autofocus: true),
              const SizedBox(height: 10),
              TextField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU (optional)')),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: priceCtrl,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                        controller: stockCtrl,
                        decoration: const InputDecoration(labelText: 'Stock'),
                        keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 10),
              TextField(controller: lowCtrl, decoration: const InputDecoration(labelText: 'Low-stock alert threshold'), keyboardType: TextInputType.number),
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
                      if (nameCtrl.text.trim().isEmpty) return;
                      setInner(() => saving = true);
                      final err = await state.upsertProduct(
                        id: editing?.id,
                        name: nameCtrl.text.trim(),
                        sku: skuCtrl.text.trim(),
                        price: double.tryParse(priceCtrl.text) ?? 0,
                        stock: int.tryParse(stockCtrl.text) ?? 0,
                        lowStockAt: int.tryParse(lowCtrl.text) ?? 5,
                      );
                      if (err != null) {
                        setInner(() {
                          saving = false;
                          error = err;
                        });
                        return;
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: Text(saving ? 'Saving…' : 'Save product'),
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
    final isAdmin = state.isAdmin;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context, state),
              icon: const Icon(Icons.add),
              label: const Text('Add product'),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${data.inventory.length} products tracked.', style: const TextStyle(color: AppColors.muted, fontSize: 14)),
            if (!isAdmin)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Staff view — ask an admin to add, edit, or remove products.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: data.inventory.isEmpty
                  ? const Center(child: Text('No products yet.', style: TextStyle(color: AppColors.muted)))
                  : ListView.separated(
                      itemCount: data.inventory.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final item = data.inventory[i];
                        final low = item.stock <= item.lowStockAt;
                        return AppCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${item.sku.isEmpty ? 'No SKU' : item.sku} · ${state.fmt(item.price)}',
                                style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              if (low) const Icon(Icons.warning_amber_outlined, size: 15, color: AppColors.brick),
                              const SizedBox(width: 4),
                              Text('${item.stock}',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: low ? AppColors.brick : AppColors.text)),
                              if (isAdmin) ...[
                                const SizedBox(width: 10),
                                IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _openForm(context, state, editing: item)),
                                IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.brick),
                                    onPressed: () async {
                                      final err = await state.deleteProduct(item.id);
                                      if (err != null && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                      }
                                    }),
                              ],
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
