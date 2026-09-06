const express = require('express');
const db = require('../db');
const { requireAuth, requireAdmin } = require('../auth');

const router = express.Router();
router.use(requireAuth, requireAdmin);

router.get('/', (req, res) => {
  const business = db.prepare('SELECT name, currency FROM business WHERE id = 1').get();
  // Staff are exported without password hashes — a backup file is not the
  // place for credential material, even hashed.
  const staff = db.prepare('SELECT id, name, username, role FROM staff').all();
  const customers = db
    .prepare('SELECT id, name, phone, created_at as createdAt, last_reminded as lastReminded FROM customers')
    .all();
  const inventory = db
    .prepare('SELECT id, name, sku, price, stock, low_stock_at as lowStockAt FROM products')
    .all();
  const transactions = db
    .prepare('SELECT * FROM transactions')
    .all()
    .map((t) => ({
      id: t.id,
      customerId: t.customer_id,
      total: t.total,
      amountPaid: t.amount_paid,
      date: t.date,
      status: t.status,
      recordedBy: t.recorded_by,
      items: db
        .prepare('SELECT product_id as itemId, name, qty, price FROM transaction_items WHERE transaction_id = ?')
        .all(t.id),
    }));
  const payments = db.prepare('SELECT id, customer_id as customerId, amount, date FROM payments').all();
  const suppliers = db
    .prepare('SELECT id, name, phone, supplies_what as suppliesWhat, notes, created_at as createdAt FROM suppliers')
    .all();
  const expenses = db
    .prepare('SELECT id, category, amount, date, note, recorded_by as recordedBy FROM expenses')
    .all();

  const filename = `sme_backup_${(business?.name || 'business').replace(/[^A-Za-z0-9]+/g, '_')}_${new Date()
    .toISOString()
    .slice(0, 10)}.json`;

  res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
  res.json({ business, staff, customers, inventory, transactions, payments, suppliers, expenses });
});

module.exports = router;
