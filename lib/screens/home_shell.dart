import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import 'dashboard_screen.dart';
import 'customers_screen.dart';
import 'inventory_screen.dart';
import 'sales_screen.dart';
import 'suppliers_screen.dart';
import 'expenses_screen.dart';
import 'reports_screen.dart';
import 'reminders_screen.dart';
import 'staff_screen.dart';
import 'settings_screen.dart';

class _NavItem {
  final String key;
  final String label;
  final IconData icon;
  final Widget Function() build;
  const _NavItem(this.key, this.label, this.icon, this.build);
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  String _current = 'dashboard';

  static const double _wideBreakpoint = 900;

  List<_NavItem> _items(bool isAdmin) => [
        _NavItem('dashboard', 'Dashboard', Icons.dashboard_outlined, () => const DashboardScreen()),
        _NavItem('customers', 'Customers', Icons.people_outline, () => const CustomersScreen()),
        _NavItem('inventory', 'Inventory', Icons.inventory_2_outlined, () => const InventoryScreen()),
        _NavItem('sales', 'Sales', Icons.point_of_sale_outlined, () => const SalesScreen()),
        _NavItem('suppliers', 'Suppliers', Icons.local_shipping_outlined, () => const SuppliersScreen()),
        if (isAdmin) _NavItem('expenses', 'Expenses', Icons.receipt_long_outlined, () => const ExpensesScreen()),
        if (isAdmin) _NavItem('reports', 'Reports', Icons.insert_chart_outlined, () => const ReportsScreen()),
        _NavItem('reminders', 'Reminders', Icons.notifications_outlined, () => const RemindersScreen()),
        if (isAdmin) _NavItem('staff', 'Staff accounts', Icons.admin_panel_settings_outlined, () => const StaffScreen()),
        if (isAdmin) _NavItem('settings', 'Settings & backup', Icons.settings_outlined, () => const SettingsScreen()),
      ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isAdmin = state.isAdmin;
    final items = _items(isAdmin);
    if (items.indexWhere((i) => i.key == _current) == -1) _current = 'dashboard';
    final activeItem = items.firstWhere((i) => i.key == _current, orElse: () => items.first);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideBreakpoint;
        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                _SideRail(
                  items: items,
                  current: _current,
                  businessName: state.data.business.name,
                  userName: state.currentUser?.name ?? '',
                  userRole: state.currentUser?.role ?? '',
                  onSelect: (k) => setState(() => _current = k),
                  onLogout: () => state.logout(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(bottom: BorderSide(color: AppColors.line)),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Text(activeItem.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            tooltip: 'Refresh from server',
                            onPressed: () => state.refresh(),
                          ),
                        ]),
                      ),
                      Expanded(child: SafeArea(top: false, child: activeItem.build())),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(activeItem.label),
            actions: [
              IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh from server', onPressed: () => state.refresh()),
              IconButton(icon: const Icon(Icons.logout), tooltip: 'Log out', onPressed: () => state.logout()),
              const SizedBox(width: 8),
            ],
          ),
          drawer: Drawer(
            backgroundColor: AppColors.ink,
            child: SafeArea(
              child: _DrawerNav(
                items: items,
                current: _current,
                businessName: state.data.business.name,
                userName: state.currentUser?.name ?? '',
                userRole: state.currentUser?.role ?? '',
                onSelect: (k) {
                  setState(() => _current = k);
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          body: SafeArea(child: activeItem.build()),
        );
      },
    );
  }
}

class _SideRail extends StatelessWidget {
  final List<_NavItem> items;
  final String current;
  final String businessName;
  final String userName;
  final String userRole;
  final void Function(String) onSelect;
  final VoidCallback onLogout;

  const _SideRail({
    required this.items,
    required this.current,
    required this.businessName,
    required this.userName,
    required this.userRole,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 236,
      color: AppColors.ink,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 20),
            child: Row(children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.account_balance_wallet_outlined, size: 15, color: AppColors.ink),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(businessName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      leading: Icon(item.icon, color: current == item.key ? AppColors.ink : Colors.white70, size: 19),
                      title: Text(item.label,
                          style: TextStyle(
                              color: current == item.key ? AppColors.ink : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5)),
                      tileColor: current == item.key ? AppColors.gold : Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      onTap: () => onSelect(item.key),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                Text(userRole, style: const TextStyle(color: Color(0xFF9FB3AC), fontSize: 11)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFE4A99D), size: 18),
            title: const Text('Log out', style: TextStyle(color: Color(0xFFE4A99D), fontSize: 13.5)),
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _DrawerNav extends StatelessWidget {
  final List<_NavItem> items;
  final String current;
  final String businessName;
  final String userName;
  final String userRole;
  final void Function(String) onSelect;

  const _DrawerNav({
    required this.items,
    required this.current,
    required this.businessName,
    required this.userName,
    required this.userRole,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.account_balance_wallet_outlined, size: 15, color: AppColors.ink),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(businessName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ]),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  child: ListTile(
                    leading: Icon(item.icon, color: current == item.key ? AppColors.ink : Colors.white70, size: 20),
                    title: Text(item.label,
                        style: TextStyle(
                            color: current == item.key ? AppColors.ink : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    tileColor: current == item.key ? AppColors.gold : Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    onTap: () => onSelect(item.key),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
              Text(userRole, style: const TextStyle(color: Color(0xFF9FB3AC), fontSize: 11.5)),
            ],
          ),
        ),
      ],
    );
  }
}
