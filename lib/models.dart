import 'dart:convert';
import 'dart:math';

String newId() {
  final rnd = Random();
  final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final salt = List.generate(4, (_) => rnd.nextInt(36).toRadixString(36)).join();
  return '$micros$salt';
}

class Business {
  String name;
  String currency;
  Business({required this.name, required this.currency});

  factory Business.fromJson(Map<String, dynamic> j) => Business(
        name: j['name'] ?? 'My Business',
        currency: j['currency'] ?? 'GH₵',
      );

  Map<String, dynamic> toJson() => {'name': name, 'currency': currency};
}

class StaffAccount {
  String id;
  String name;
  String username;
  String password;
  String role; // 'admin' | 'staff'
  StaffAccount({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.role,
  });

  factory StaffAccount.fromJson(Map<String, dynamic> j) => StaffAccount(
        id: j['id'],
        name: j['name'],
        username: j['username'],
        password: j['password'] ?? '', // the server never sends this back
        role: j['role'] ?? 'staff',
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'username': username, 'password': password, 'role': role};
}

class Customer {
  String id;
  String name;
  String phone;
  String createdAt;
  String? lastReminded;
  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.createdAt,
    this.lastReminded,
  });

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: j['id'],
        name: j['name'],
        phone: j['phone'],
        createdAt: j['createdAt'] ?? '',
        lastReminded: j['lastReminded'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'createdAt': createdAt,
        'lastReminded': lastReminded,
      };
}

class Product {
  String id;
  String name;
  String sku;
  double price;
  int stock;
  int lowStockAt;
  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.stock,
    required this.lowStockAt,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'],
        name: j['name'],
        sku: j['sku'] ?? '',
        price: (j['price'] as num).toDouble(),
        stock: (j['stock'] as num).toInt(),
        lowStockAt: (j['lowStockAt'] as num?)?.toInt() ?? 5,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'sku': sku, 'price': price, 'stock': stock, 'lowStockAt': lowStockAt};
}

class SaleItem {
  String itemId;
  String name;
  int qty;
  double price;
  SaleItem({required this.itemId, required this.name, required this.qty, required this.price});

  factory SaleItem.fromJson(Map<String, dynamic> j) => SaleItem(
        itemId: j['itemId'],
        name: j['name'],
        qty: (j['qty'] as num).toInt(),
        price: (j['price'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'itemId': itemId, 'name': name, 'qty': qty, 'price': price};
}

class SaleTransaction {
  String id;
  String customerId;
  List<SaleItem> items;
  double total;
  double amountPaid;
  String date;
  String status; // paid | partial | unpaid
  String? recordedBy;
  SaleTransaction({
    required this.id,
    required this.customerId,
    required this.items,
    required this.total,
    required this.amountPaid,
    required this.date,
    required this.status,
    this.recordedBy,
  });

  factory SaleTransaction.fromJson(Map<String, dynamic> j) => SaleTransaction(
        id: j['id'],
        customerId: j['customerId'],
        items: (j['items'] as List).map((e) => SaleItem.fromJson(e)).toList(),
        total: (j['total'] as num).toDouble(),
        amountPaid: (j['amountPaid'] as num).toDouble(),
        date: j['date'],
        status: j['status'],
        recordedBy: j['recordedBy'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'items': items.map((e) => e.toJson()).toList(),
        'total': total,
        'amountPaid': amountPaid,
        'date': date,
        'status': status,
        'recordedBy': recordedBy,
      };
}

class PaymentRecord {
  String id;
  String customerId;
  double amount;
  String date;
  PaymentRecord({required this.id, required this.customerId, required this.amount, required this.date});

  factory PaymentRecord.fromJson(Map<String, dynamic> j) => PaymentRecord(
        id: j['id'],
        customerId: j['customerId'],
        amount: (j['amount'] as num).toDouble(),
        date: j['date'],
      );

  Map<String, dynamic> toJson() => {'id': id, 'customerId': customerId, 'amount': amount, 'date': date};
}

class Supplier {
  String id;
  String name;
  String phone;
  String suppliesWhat;
  String notes;
  String createdAt;
  Supplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.suppliesWhat,
    required this.notes,
    required this.createdAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> j) => Supplier(
        id: j['id'],
        name: j['name'],
        phone: j['phone'] ?? '',
        suppliesWhat: j['suppliesWhat'] ?? '',
        notes: j['notes'] ?? '',
        createdAt: j['createdAt'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'suppliesWhat': suppliesWhat,
        'notes': notes,
        'createdAt': createdAt,
      };
}

const List<String> expenseCategories = [
  'Rent',
  'Utilities',
  'Transport',
  'Salaries',
  'Stock purchase',
  'Repairs',
  'Marketing',
  'Other',
];

class Expense {
  String id;
  String category;
  double amount;
  String date;
  String note;
  String? recordedBy;
  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.note,
    this.recordedBy,
  });

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'],
        category: j['category'] ?? 'Other',
        amount: (j['amount'] as num).toDouble(),
        date: j['date'],
        note: j['note'] ?? '',
        recordedBy: j['recordedBy'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'amount': amount,
        'date': date,
        'note': note,
        'recordedBy': recordedBy,
      };
}

class AppData {
  Business business;
  List<StaffAccount> staff;
  List<Customer> customers;
  List<Product> inventory;
  List<SaleTransaction> transactions;
  List<PaymentRecord> payments;
  List<Supplier> suppliers;
  List<Expense> expenses;

  AppData({
    required this.business,
    required this.staff,
    required this.customers,
    required this.inventory,
    required this.transactions,
    required this.payments,
    required this.suppliers,
    required this.expenses,
  });

  factory AppData.empty() => AppData(
        business: Business(name: 'My Business', currency: 'GH₵'),
        staff: [
          StaffAccount(id: newId(), name: 'Admin User', username: 'admin', password: 'admin123', role: 'admin'),
        ],
        customers: [],
        inventory: [],
        transactions: [],
        payments: [],
        suppliers: [],
        expenses: [],
      );

  factory AppData.fromJson(Map<String, dynamic> j) => AppData(
        business: Business.fromJson(j['business'] ?? {}),
        staff: (j['staff'] as List? ?? []).map((e) => StaffAccount.fromJson(e)).toList(),
        customers: (j['customers'] as List? ?? []).map((e) => Customer.fromJson(e)).toList(),
        inventory: (j['inventory'] as List? ?? []).map((e) => Product.fromJson(e)).toList(),
        transactions: (j['transactions'] as List? ?? []).map((e) => SaleTransaction.fromJson(e)).toList(),
        payments: (j['payments'] as List? ?? []).map((e) => PaymentRecord.fromJson(e)).toList(),
        suppliers: (j['suppliers'] as List? ?? []).map((e) => Supplier.fromJson(e)).toList(),
        expenses: (j['expenses'] as List? ?? []).map((e) => Expense.fromJson(e)).toList(),
      );

  Map<String, dynamic> toJson() => {
        'business': business.toJson(),
        'staff': staff.map((e) => e.toJson()).toList(),
        'customers': customers.map((e) => e.toJson()).toList(),
        'inventory': inventory.map((e) => e.toJson()).toList(),
        'transactions': transactions.map((e) => e.toJson()).toList(),
        'payments': payments.map((e) => e.toJson()).toList(),
        'suppliers': suppliers.map((e) => e.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
      };

  String encode() => jsonEncode(toJson());
  factory AppData.decode(String s) => AppData.fromJson(jsonDecode(s));
}

AppData sampleData() {
  final d = AppData.empty();
  final c1 = newId(), c2 = newId(), c3 = newId();
  d.customers.addAll([
    Customer(id: c1, name: 'Ama Boateng', phone: '024 555 1122', createdAt: '2026-06-01'),
    Customer(id: c2, name: 'Kwame Owusu', phone: '020 333 8899', createdAt: '2026-06-10'),
    Customer(id: c3, name: 'Efua Mensah', phone: '055 777 2244', createdAt: '2026-07-02'),
  ]);
  final p1 = newId(), p2 = newId(), p3 = newId(), p4 = newId();
  d.inventory.addAll([
    Product(id: p1, name: 'Bag of Rice (25kg)', sku: 'RICE-25', price: 380, stock: 14, lowStockAt: 5),
    Product(id: p2, name: 'Cooking Oil (5L)', sku: 'OIL-5L', price: 120, stock: 3, lowStockAt: 5),
    Product(id: p3, name: 'Bar Soap (dozen)', sku: 'SOAP-12', price: 60, stock: 22, lowStockAt: 8),
    Product(id: p4, name: 'Sachet Water (bag)', sku: 'WATER-BAG', price: 8, stock: 40, lowStockAt: 15),
  ]);

  d.suppliers.addAll([
    Supplier(
        id: newId(),
        name: 'Golden Grains Ltd',
        phone: '030 222 4411',
        suppliesWhat: 'Rice, grains',
        notes: 'Delivers every Monday',
        createdAt: '2026-05-01'),
    Supplier(
        id: newId(),
        name: 'Coastal Oils & Soap',
        phone: '024 888 1200',
        suppliesWhat: 'Cooking oil, soap',
        notes: 'Requires 3 days notice',
        createdAt: '2026-05-15'),
  ]);

  String daysAgoStr(int days) {
    final dt = DateTime.now().subtract(Duration(days: days));
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  d.expenses.addAll([
    Expense(id: newId(), category: 'Rent', amount: 800, date: daysAgoStr(25), note: 'Shop rent', recordedBy: 'Admin User'),
    Expense(id: newId(), category: 'Transport', amount: 60, date: daysAgoStr(10), note: 'Delivery van fuel', recordedBy: 'Admin User'),
    Expense(id: newId(), category: 'Utilities', amount: 150, date: daysAgoStr(5), note: 'Electricity bill', recordedBy: 'Admin User'),
  ]);

  SaleTransaction mk(String customerId, List<SaleItem> items, int daysAgo, double paidRatio) {
    final total = items.fold<double>(0, (s, it) => s + it.qty * it.price);
    final amountPaid = (total * paidRatio).roundToDouble();
    final dateStr = daysAgoStr(daysAgo);
    final status = amountPaid >= total ? 'paid' : (amountPaid > 0 ? 'partial' : 'unpaid');
    return SaleTransaction(
        id: newId(),
        customerId: customerId,
        items: items,
        total: total,
        amountPaid: amountPaid,
        date: dateStr,
        status: status);
  }

  d.transactions.addAll([
    mk(c1, [SaleItem(itemId: p1, name: 'Bag of Rice (25kg)', qty: 1, price: 380)], 20, 1),
    mk(c1, [SaleItem(itemId: p2, name: 'Cooking Oil (5L)', qty: 2, price: 120)], 8, 0.5),
    mk(c2, [SaleItem(itemId: p3, name: 'Bar Soap (dozen)', qty: 3, price: 60)], 15, 0),
    mk(c2, [SaleItem(itemId: p4, name: 'Sachet Water (bag)', qty: 5, price: 8)], 3, 1),
    mk(c3, [SaleItem(itemId: p1, name: 'Bag of Rice (25kg)', qty: 2, price: 380)], 30, 0.25),
  ]);
  return d;
}
