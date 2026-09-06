import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  void _openAddDialog(BuildContext context, AppState state) {
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'staff';
    String error = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add staff account'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full name'), autofocus: true),
              const SizedBox(height: 10),
              TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Username')),
              const SizedBox(height: 10),
              TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: role,
                items: const [
                  DropdownMenuItem(value: 'staff', child: Text('Staff')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) => setState(() => role = v ?? 'staff'),
                decoration: const InputDecoration(labelText: 'Role'),
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
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || userCtrl.text.trim().isEmpty || passCtrl.text.isEmpty) {
                  setState(() => error = 'Fill in all fields.');
                  return;
                }
                final err = await state.addStaff(
                    name: nameCtrl.text.trim(), username: userCtrl.text.trim(), password: passCtrl.text, role: role);
                if (err != null) {
                  setState(() => error = err);
                  return;
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Create account'),
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddDialog(context, state),
        icon: const Icon(Icons.add),
        label: const Text('Add staff'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${data.staff.length} accounts with access to this system.', style: const TextStyle(color: AppColors.muted, fontSize: 14)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: data.staff.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final s = data.staff[i];
                  final isSelf = s.id == state.currentUser?.id;
                  return AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${s.name}${isSelf ? ' (you)' : ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${s.username} · ${s.role}', style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                      trailing: isSelf
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.brick),
                              onPressed: () async {
                                final err = await state.removeStaff(s.id);
                                if (err != null && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                }
                              },
                            ),
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
