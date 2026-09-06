const express = require('express');
const db = require('../db');
const { newId, todayIso } = require('../utils');
const { requireAuth, requireAdmin } = require('../auth');

const router = express.Router();
router.use(requireAuth);

function balanceFor(customerId) {
  const t = db
    .prepare('SELECT COALESCE(SUM(total),0) as total, COALESCE(SUM(amount_paid),0) as paid FROM transactions WHERE customer_id = ?')
    .get(customerId);
  const extra = db.prepare('SELECT COALESCE(SUM(amount),0) as a FROM payments WHERE customer_id = ?').get(customerId);
  const bal = t.total - t.paid - extra.a;
  return bal < 0 ? 0 : Math.round(bal * 100) / 100;
}

function itemsFor(transactionId) {
  return db
    .prepare('SELECT product_id as itemId, name, qty, price FROM transaction_items WHERE transaction_id = ?')
    .all(transactionId);
}

router.get('/', (req, res) => {
  const rows = db.prepare('SELECT * FROM customers ORDER BY name').all();
  const result = rows.map((c) => ({
    id: c.id,
    name: c.name,
    phone: c.phone,
    createdAt: c.created_at,
    lastReminded: c.last_reminded,
    balance: balanceFor(c.id),
    purchaseCount: db.prepare('SELECT COUNT(*) as c FROM transactions WHERE customer_id = ?').get(c.id).c,
  }));
  res.json(result);
});

router.get('/:id', (req, res) => {
  const c = db.prepare('SELECT * FROM customers WHERE id = ?').get(req.params.id);
  if (!c) return res.status(404).json({ error: 'Customer not found.' });
  const transactions = db
    .prepare('SELECT * FROM transactions WHERE customer_id = ? ORDER BY date DESC')
    .all(c.id)
    .map((t) => ({
      id: t.id,
      customerId: t.customer_id,
      total: t.total,
      amountPaid: t.amount_paid,
      date: t.date,
      status: t.status,
      recordedBy: t.recorded_by,
      items: itemsFor(t.id),
    }));
  const payments = db.prepare('SELECT * FROM payments WHERE customer_id = ? ORDER BY date DESC').all(c.id);
  res.json({
    id: c.id,
    name: c.name,
    phone: c.phone,
    createdAt: c.created_at,
    lastReminded: c.last_reminded,
    balance: balanceFor(c.id),
    transactions,
    payments,
  });
});

router.post('/', (req, res) => {
  const { name, phone } = req.body || {};
  if (!name?.trim() || !phone?.trim()) return res.status(400).json({ error: 'name and phone are required.' });
  const id = newId();
  const createdAt = todayIso();
  db.prepare('INSERT INTO customers (id, name, phone, created_at) VALUES (?,?,?,?)').run(id, name.trim(), phone.trim(), createdAt);
  res.status(201).json({ id, name: name.trim(), phone: phone.trim(), createdAt, lastReminded: null, balance: 0, purchaseCount: 0 });
});

router.delete('/:id', requireAdmin, (req, res) => {
  const result = db.prepare('DELETE FROM customers WHERE id = ?').run(req.params.id);
  if (result.changes === 0) return res.status(404).json({ error: 'Customer not found.' });
  res.status(204).end();
});

router.post('/:id/payments', (req, res) => {
  const { amount } = req.body || {};
  const amt = Number(amount);
  if (!amt || amt <= 0) return res.status(400).json({ error: 'A positive amount is required.' });
  const customer = db.prepare('SELECT id FROM customers WHERE id = ?').get(req.params.id);
  if (!customer) return res.status(404).json({ error: 'Customer not found.' });

  const id = newId();
  const date = todayIso();
  db.prepare('INSERT INTO payments (id, customer_id, amount, date) VALUES (?,?,?,?)').run(id, req.params.id, amt, date);
  res.status(201).json({ id, customerId: req.params.id, amount: amt, date, balance: balanceFor(req.params.id) });
});

router.post('/:id/remind', (req, res) => {
  const customer = db.prepare('SELECT id FROM customers WHERE id = ?').get(req.params.id);
  if (!customer) return res.status(404).json({ error: 'Customer not found.' });
  const date = todayIso();
  db.prepare('UPDATE customers SET last_reminded = ? WHERE id = ?').run(date, req.params.id);
  res.json({ id: req.params.id, lastReminded: date });
});

module.exports = router;
