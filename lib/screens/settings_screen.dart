import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameCtrl;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _nameCtrl = TextEditingController(text: state.data.business.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool _savingName = false;

  Future<void> _saveName(AppState state) async {
    setState(() => _savingName = true);
    final err = await state.updateBusinessName(_nameCtrl.text);
    if (!mounted) return;
    setState(() => _savingName = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Business name saved.')),
    );
  }

  Future<void> _export(AppState state) async {
    setState(() => _exporting = true);
    String message;
    try {
      message = await state.exportBackup();
    } catch (e) {
      message = 'Could not export backup: $e';
    }
    if (mounted) {
      setState(() => _exporting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final data = state.data;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Business profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 10),
          AppCard(
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Business name'),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _savingName ? null : () => _saveName(state),
                child: _savingName
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Backup', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Download a full JSON copy of your customers, inventory, sales, expenses, suppliers, and staff accounts. '
                  'Keep it somewhere safe — it can be used to restore or migrate your data.',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _exporting ? null : () => _export(state),
                  icon: _exporting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_outlined, size: 17),
                  label: Text(_exporting ? 'Preparing…' : 'Export JSON backup'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Data summary', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              children: [
                _row('Customers', '${data.customers.length}'),
                _row('Products', '${data.inventory.length}'),
                _row('Transactions', '${data.transactions.length}'),
                _row('Suppliers', '${data.suppliers.length}'),
                _row('Expenses', '${data.expenses.length}'),
                _row('Staff accounts', '${data.staff.length}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13.5)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
        ],
      ),
    );
  }
}
