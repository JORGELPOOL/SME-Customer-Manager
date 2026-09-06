import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class _SaleLine {
  String? productId;
  int qty;
  _SaleLine({this.productId, this.qty = 1});
}

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});
  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String? customerId;
  List<_SaleLine> lines = [_SaleLine()];
  final _paidCtrl = TextEditingController();
  String notice = '';
  bool submitting = false;

  @override
  void dispose() {
    _paidCtrl.dispose();
    super.dispose();
  }

  double _total(AppState state) {
    double t = 0;
    for (final l in lines) {
      if (l.productId == null) continue;
      final matches = state.data.inventory.where((e) => e.id == l.productId);
      if (matches.isEmpty) continue;
      t += matches.first.price * l.qty;
    }
    return t;
  }

  Future<void> _submit(AppState state) async {
    final validLines = lines.where((l) => l.productId != null && l.qty > 0).toList();
    if (customerId == null || validLines.isEmpty) return;
    // Only productId + qty are sent — the server looks up the current price
    // itself, so a stale locally-cached price is never what actually gets
    // charged.
    final items = validLines.map((l) => {'productId': l.productId, 'qty': l.qty}).toList();
    final paid = double.tryParse(_paidCtrl.text) ?? 0;

    setState(() {
      submitting = true;
      notice = '';
    });
    final err = await state.recordSale(customerId: customerId!, items: items, amountPaid: paid);
    if (!mounted) return;

    if (err != null) {
      setState(() => submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    setState(() {
      submitting = false;
      customerId = null;
      lines = [_SaleLine()];
      _paidCtrl.clear();
      notice = 'Sale recorded.';
    });
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => notice = '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final data = state.data;
    final total = _total(state);
    final recent = [...data.transactions]..sort((a, b) => b.date.compareTo(a.date));
    final recentTwelve = recent.take(12).toList();

    String customerName(String id) {
      final match = data.customers.where((c) => c.id == id);
      return match.isEmpty ? 'Walk-in' : match.first.name;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Record a new sale — stock and customer debt update automatically.',
              style: TextStyle(color: AppColors.muted, fontSize: 14)),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Customer', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: customerId,
                  isExpanded: true,
                  items: data.customers
                      .map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} — ${c.phone}', overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => customerId = v),
                  decoration: const InputDecoration(hintText: 'Select a customer…'),
                ),
                const SizedBox(height: 14),
                const Text('Items', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                for (int i = 0; i < lines.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: lines[i].productId,
                          isExpanded: true,
                          items: data.inventory
                              .map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text('${p.name} (${state.fmt(p.price)}, ${p.stock} left)',
                                      overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (v) => setState(() => lines[i].productId = v),
                          decoration: const InputDecoration(hintText: 'Product', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 64,
                        child: TextFormField(
                          initialValue: lines[i].qty.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true, labelText: 'Qty'),
                          onChanged: (v) => lines[i].qty = int.tryParse(v) ?? 1,
                        ),
                      ),
                      if (lines.length > 1)
                        IconButton(
                          icon: const Icon(Icons.close, size: 16, color: AppColors.brick),
                          onPressed: () => setState(() => lines.removeAt(i)),
                        ),
                    ]),
                  ),
                TextButton.icon(
                  onPressed: () => setState(() => lines.add(_SaleLine())),
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text('Add another item'),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total', style: TextStyle(color: AppColors.muted)),
                    Text(state.fmt(total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ]),
                ),
                const SizedBox(height: 14),
                const Text('Amount paid now', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _paidCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: '0.00 (leave blank if fully on credit)'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting ? null : () => _submit(state),
                      child: submitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Record sale'),
                    )),
                if (notice.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(children: [
                      const Icon(Icons.check_circle_outline, size: 15, color: AppColors.sage),
                      const SizedBox(width: 6),
                      Text(notice, style: const TextStyle(color: AppColors.sage, fontSize: 13)),
                    ]),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Align(alignment: Alignment.centerLeft, child: Text('Recent sales', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
              ),
              const Divider(height: 1),
              if (recentTwelve.isEmpty)
                const Padding(padding: EdgeInsets.all(20), child: Text('No sales yet.', style: TextStyle(color: AppColors.muted))),
              for (final t in recentTwelve)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    Expanded(child: Text(customerName(t.customerId), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5))),
                    Text(state.fmt(t.total), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 10),
                    StatusChip(status: t.status),
                    const SizedBox(width: 10),
                    Text(t.date, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ]),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}
