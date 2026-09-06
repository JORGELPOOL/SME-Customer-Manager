import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../models.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});
  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  String query = '';

  void _openForm(BuildContext context, AppState state, {Supplier? editing}) {
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final phoneCtrl = TextEditingController(text: editing?.phone ?? '');
    final suppliesCtrl = TextEditingController(text: editing?.suppliesWhat ?? '');
    final notesCtrl = TextEditingController(text: editing?.notes ?? '');
    String error = '';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: Text(editing != null ? 'Edit supplier' : 'Add supplier'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Supplier name'), autofocus: true),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone number'), keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              TextField(controller: suppliesCtrl, decoration: const InputDecoration(labelText: 'Supplies (e.g. Rice, oil)')),
              const SizedBox(height: 10),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)'), maxLines: 2),
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
                      final err = await state.upsertSupplier(
                        id: editing?.id,
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        suppliesWhat: suppliesCtrl.text.trim(),
                        notes: notesCtrl.text.trim(),
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
    final isAdmin = state.isAdmin;
    final filtered = data.suppliers
        .where((s) =>
            s.name.toLowerCase().contains(query.toLowerCase()) ||
            s.suppliesWhat.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context, state),
              icon: const Icon(Icons.add),
              label: const Text('Add supplier'),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${data.suppliers.length} suppliers on record.', style: const TextStyle(color: AppColors.muted, fontSize: 14)),
            if (!isAdmin)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Staff view — ask an admin to add or edit suppliers.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(hintText: 'Search suppliers or what they supply', prefixIcon: Icon(Icons.search, size: 20)),
              onChanged: (v) => setState(() => query = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No suppliers found.', style: TextStyle(color: AppColors.muted)))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final s = filtered[i];
                        return AppCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                                    const SizedBox(height: 3),
                                    if (s.phone.isNotEmpty)
                                      Text(s.phone, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                                    if (s.suppliesWhat.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text('Supplies: ${s.suppliesWhat}', style: const TextStyle(fontSize: 12.5)),
                                      ),
                                    if (s.notes.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(s.notes, style: const TextStyle(color: AppColors.muted, fontSize: 12, fontStyle: FontStyle.italic)),
                                      ),
                                  ],
                                ),
                              ),
                              if (isAdmin)
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _openForm(context, state, editing: s)),
                                  IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.brick),
                                      onPressed: () async {
                                        final err = await state.deleteSupplier(s.id);
                                        if (err != null && context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                        }
                                      }),
                                ]),
                            ],
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
