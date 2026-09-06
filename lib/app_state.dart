import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';
import 'backup/backup_service.dart' as backup;

class AppState extends ChangeNotifier {
  static const _tokenKey = 'sme_api_token_v1';
  static const _baseUrlKey = 'sme_api_base_url_v1';

  late ApiClient _api;
  String apiBaseUrl = defaultApiBaseUrl;

  AppData data = AppData.empty();
  StaffAccount? currentUser;
  bool loading = true;
  String loginError = '';
  String? errorMessage;

  bool get isAdmin => currentUser?.role == 'admin';

  /// Runs a mutating call against the API and reports success/failure as a
  /// return value (null = success) instead of throwing, so screens can show
  /// an inline message without wrapping every call in try/catch themselves.
  Future<String?> _run(Future<void> Function() action) async {
    try {
      await action();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Could not reach the server. Check your connection and try again.';
    }
  }

  Future<void> init() async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 10));
      apiBaseUrl = prefs.getString(_baseUrlKey) ?? defaultApiBaseUrl;
      final token = prefs.getString(_tokenKey);
      _api = ApiClient(baseUrl: apiBaseUrl, token: token);

      if (token != null) {
        try {
          final res = await _api.get('/auth/me').timeout(const Duration(seconds: 10));
          currentUser = StaffAccount.fromJson({...res['user'], 'password': ''});
          await _refreshAll();
        } catch (e) {
          // Stale/expired token, or the server just isn't reachable right
          // now. Either way, don't get stuck — drop the token and let the
          // person sign in fresh instead of hanging or looping forever.
          await prefs.remove(_tokenKey);
          currentUser = null;
        }
      }
    } catch (e) {
      errorMessage = 'Could not start up cleanly. You can still try to sign in.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshAll() async {
    try {
      final results = await Future.wait([
        _api.get('/business'),
        _api.get('/customers'),
        _api.get('/products'),
        _api.get('/transactions'),
        _api.get('/payments'),
        _api.get('/suppliers'),
      ]).timeout(const Duration(seconds: 20));

      data.business = Business.fromJson(results[0] as Map<String, dynamic>);
      data.customers = (results[1] as List).map((e) => Customer.fromJson(e)).toList();
      data.inventory = (results[2] as List).map((e) => Product.fromJson(e)).toList();
      data.transactions = (results[3] as List).map((e) => SaleTransaction.fromJson(e)).toList();
      data.payments = (results[4] as List).map((e) => PaymentRecord.fromJson(e)).toList();
      data.suppliers = (results[5] as List).map((e) => Supplier.fromJson(e)).toList();

      if (isAdmin) {
        final adminResults = await Future.wait([_api.get('/expenses'), _api.get('/staff')])
            .timeout(const Duration(seconds: 20));
        data.expenses = (adminResults[0] as List).map((e) => Expense.fromJson(e)).toList();
        data.staff = (adminResults[1] as List).map((e) => StaffAccount.fromJson(e)).toList();
      } else {
        data.expenses = [];
        data.staff = [];
      }
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = 'Could not refresh data: ${e.message}';
    } catch (e) {
      errorMessage = 'Could not reach the server at $apiBaseUrl. Check your connection and the server address.';
    }
    notifyListeners();
  }

  /// Manually pulls the latest data from the server — useful since other
  /// staff/devices can change shared data at any time.
  Future<void> refresh() => _refreshAll();

  Future<void> login(String username, String password) async {
    loginError = '';
    notifyListeners();
    try {
      final res = await _api.post('/auth/login', {'username': username, 'password': password});
      final token = res['token'] as String;
      _api.token = token;
      try {
        final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 10));
        await prefs.setString(_tokenKey, token);
      } catch (_) {
        // Session just won't survive an app restart; login for this run still works.
      }
      currentUser = StaffAccount.fromJson({...res['user'] as Map<String, dynamic>, 'password': ''});
      await _refreshAll();
    } on ApiException catch (e) {
      loginError = e.message;
    } catch (e) {
      loginError = 'Could not reach the server at $apiBaseUrl. Check the server address and try again.';
    }
    notifyListeners();
  }

  Future<void> logout() async {
    currentUser = null;
    data = AppData.empty();
    _api.token = null;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 10));
      await prefs.remove(_tokenKey);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> updateApiBaseUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    apiBaseUrl = trimmed;
    _api.baseUrl = trimmed;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 10));
      await prefs.setString(_baseUrlKey, trimmed);
    } catch (_) {}
    notifyListeners();
  }

  void dismissError() {
    errorMessage = null;
    notifyListeners();
  }

  /// Debt balance is computed client-side from the full transactions and
  /// payments lists (both synced from the server), matching how the server
  /// computes it — kept this way so every screen that already calls this
  /// method needed no changes.
  double customerBalance(String customerId) {
    double purchased = 0, paidAtSale = 0;
    for (final t in data.transactions) {
      if (t.customerId == customerId) {
        purchased += t.total;
        paidAtSale += t.amountPaid;
      }
    }
    double extraPaid = 0;
    for (final p in data.payments) {
      if (p.customerId == customerId) extraPaid += p.amount;
    }
    final bal = purchased - paidAtSale - extraPaid;
    return bal < 0 ? 0 : bal;
  }

  // ---- Business ----
  Future<String?> updateBusinessName(String name) => _run(() async {
        final res = await _api.put('/business', {'name': name});
        data.business = Business.fromJson(res as Map<String, dynamic>);
      });

  // ---- Customers ----
  Future<String?> addCustomer(String name, String phone) => _run(() async {
        final res = await _api.post('/customers', {'name': name, 'phone': phone});
        data.customers.add(Customer.fromJson(res as Map<String, dynamic>));
      });

  Future<String?> deleteCustomer(String id) => _run(() async {
        await _api.delete('/customers/$id');
        data.customers.removeWhere((c) => c.id == id);
      });

  Future<String?> addPayment(String customerId, double amount) => _run(() async {
        final res = await _api.post('/customers/$customerId/payments', {'amount': amount});
        data.payments.add(PaymentRecord.fromJson(res as Map<String, dynamic>));
      });

  // ---- Inventory ----
  Future<String?> upsertProduct({
    String? id,
    required String name,
    required String sku,
    required double price,
    required int stock,
    required int lowStockAt,
  }) =>
      _run(() async {
        final body = {'name': name, 'sku': sku, 'price': price, 'stock': stock, 'lowStockAt': lowStockAt};
        if (id != null) {
          final res = await _api.put('/products/$id', body);
          final updated = Product.fromJson(res as Map<String, dynamic>);
          final idx = data.inventory.indexWhere((p) => p.id == id);
          if (idx != -1) data.inventory[idx] = updated;
        } else {
          final res = await _api.post('/products', body);
          data.inventory.add(Product.fromJson(res as Map<String, dynamic>));
        }
      });

  Future<String?> deleteProduct(String id) => _run(() async {
        await _api.delete('/products/$id');
        data.inventory.removeWhere((p) => p.id == id);
      });

  // ---- Sales ----
  /// [items] is a list of `{ 'productId': ..., 'qty': ... }` maps — price is
  /// deliberately not sent; the server looks up the current price itself so
  /// a stale local price can never be used for a real sale.
  Future<String?> recordSale({
    required String customerId,
    required List<Map<String, dynamic>> items,
    required double amountPaid,
  }) =>
      _run(() async {
        final res = await _api.post('/transactions', {
          'customerId': customerId,
          'items': items,
          'amountPaid': amountPaid,
        });
        data.transactions.add(SaleTransaction.fromJson(res as Map<String, dynamic>));
        // Stock was just decremented server-side — pull the fresh levels
        // rather than trying to replicate that arithmetic locally.
        final products = await _api.get('/products');
        data.inventory = (products as List).map((e) => Product.fromJson(e)).toList();
      });

  // ---- Reminders ----
  Future<void> markReminded(String customerId) async {
    try {
      final res = await _api.post('/customers/$customerId/remind');
      final idx = data.customers.indexWhere((c) => c.id == customerId);
      if (idx != -1) data.customers[idx].lastReminded = res['lastReminded'] as String?;
      notifyListeners();
    } catch (_) {
      // Non-critical — the copy-to-clipboard action already succeeded from
      // the person's point of view; silently skip the "last reminded" stamp
      // rather than interrupting them with an error for this.
    }
  }

  // ---- Suppliers ----
  Future<String?> upsertSupplier({
    String? id,
    required String name,
    required String phone,
    required String suppliesWhat,
    required String notes,
  }) =>
      _run(() async {
        final body = {'name': name, 'phone': phone, 'suppliesWhat': suppliesWhat, 'notes': notes};
        if (id != null) {
          final res = await _api.put('/suppliers/$id', body);
          final updated = Supplier.fromJson(res as Map<String, dynamic>);
          final idx = data.suppliers.indexWhere((s) => s.id == id);
          if (idx != -1) data.suppliers[idx] = updated;
        } else {
          final res = await _api.post('/suppliers', body);
          data.suppliers.add(Supplier.fromJson(res as Map<String, dynamic>));
        }
      });

  Future<String?> deleteSupplier(String id) => _run(() async {
        await _api.delete('/suppliers/$id');
        data.suppliers.removeWhere((s) => s.id == id);
      });

  // ---- Expenses ----
  Future<String?> addExpense({
    required String category,
    required double amount,
    required String date,
    required String note,
  }) =>
      _run(() async {
        final res = await _api.post('/expenses', {'category': category, 'amount': amount, 'date': date, 'note': note});
        data.expenses.add(Expense.fromJson(res as Map<String, dynamic>));
      });

  Future<String?> deleteExpense(String id) => _run(() async {
        await _api.delete('/expenses/$id');
        data.expenses.removeWhere((e) => e.id == id);
      });

  // ---- Staff ----
  Future<String?> addStaff({
    required String name,
    required String username,
    required String password,
    required String role,
  }) =>
      _run(() async {
        final res = await _api.post('/staff', {'name': name, 'username': username, 'password': password, 'role': role});
        data.staff.add(StaffAccount.fromJson({...res as Map<String, dynamic>, 'password': ''}));
      });

  Future<String?> removeStaff(String id) => _run(() async {
        await _api.delete('/staff/$id');
        data.staff.removeWhere((s) => s.id == id);
      });

  // ---- Backup ----
  /// Downloads the server's authoritative backup (not a locally-encoded
  /// copy), so the exported file always matches what's actually in the
  /// shared database.
  Future<String> exportBackup() async {
    final res = await _api.get('/backup');
    final jsonStr = jsonEncode(res);
    final safeName = data.business.name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final filename = 'sme_backup_${safeName}_${DateTime.now().toIso8601String().substring(0, 10)}.json';
    return backup.downloadBackup(jsonStr, filename);
  }

  String fmt(num n) {
    final symbol = data.business.currency;
    final fixed = n.toStringAsFixed(2);
    final parts = fixed.split('.');
    var intPart = parts[0];
    final negative = intPart.startsWith('-');
    if (negative) intPart = intPart.substring(1);
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    return '$symbol${negative ? '-' : ''}${buffer.toString()}.${parts[1]}';
  }
}
