const express = require('express');
const db = require('../db');
const { newId, todayIso } = require('../utils');
const { requireAuth } = require('../auth');

const router = express.Router();
router.use(requireAuth);

function itemsFor(transactionId) {
  return db
    .prepare('SELECT product_id as itemId, name, qty, price FROM transaction_items WHERE transaction_id = ?')
    .all(transactionId);
}

router.get('/', (req, res) => {
  const { customerId, limit } = req.query;
  let rows;
  if (customerId) {
    rows = db.prepare('SELECT * FROM transactions WHERE customer_id = ? ORDER BY date DESC').all(customerId);
  } else if (limit) {
    rows = db.prepare('SELECT * FROM transactions ORDER BY date DESC LIMIT ?').all(Number(limit));
  } else {
    rows = db.prepare('SELECT * FROM transactions ORDER BY date DESC').all();
  }
  res.json(
    rows.map((t) => ({
      id: t.id,
      customerId: t.customer_id,
      total: t.total,
      amountPaid: t.amount_paid,
      date: t.date,
      status: t.status,
      recordedBy: t.recorded_by,
      items: itemsFor(t.id),
    }))
  );
});

router.post('/', (req, res) => {
  const { customerId, items, amountPaid } = req.body || {};
  if (!customerId || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ error: 'customerId and at least one item are required.' });
  }
  const customer = db.prepare('SELECT id FROM customers WHERE id = ?').get(customerId);
  if (!customer) return res.status(404).json({ error: 'Customer not found.' });

  const resolved = [];
  for (const it of items) {
    const product = db.prepare('SELECT * FROM products WHERE id = ?').get(it.productId);
    if (!product) return res.status(400).json({ error: `Product ${it.productId} not found.` });
    const qty = Number(it.qty);
    if (!qty || qty <= 0) return res.status(400).json({ error: 'Each item needs a positive quantity.' });
    if (product.stock < qty) {
      return res.status(409).json({ error: `Not enough stock for "${product.name}" (${product.stock} left).` });
    }
    resolved.push({ product, qty });
  }

  const total = resolved.reduce((s, it) => s + it.qty * it.product.price, 0);
  const paid = Math.min(Number(amountPaid) || 0, total);
  const status = paid >= total ? 'paid' : paid > 0 ? 'partial' : 'unpaid';
  const txId = newId();
  const date = todayIso();

  const insertTx = db.prepare(
    'INSERT INTO transactions (id, customer_id, total, amount_paid, date, status, recorded_by) VALUES (?,?,?,?,?,?,?)'
  );
  const insertItem = db.prepare(
    'INSERT INTO transaction_items (transaction_id, product_id, name, qty, price) VALUES (?,?,?,?,?)'
  );
  const updateStock = db.prepare('UPDATE products SET stock = stock - ? WHERE id = ?');

  const run = db.transaction(() => {
    insertTx.run(txId, customerId, total, paid, date, status, req.user.name);
    for (const it of resolved) {
      insertItem.run(txId, it.product.id, it.product.name, it.qty, it.product.price);
      updateStock.run(it.qty, it.product.id);
    }
  });
  run();

  res.status(201).json({
    id: txId,
    customerId,
    total,
    amountPaid: paid,
    date,
    status,
    recordedBy: req.user.name,
    items: resolved.map((it) => ({ itemId: it.product.id, name: it.product.name, qty: it.qty, price: it.product.price })),
  });
});

module.exports = router;
