const express = require('express');
const db = require('../db');
const { newId } = require('../utils');
const { requireAuth, requireAdmin } = require('../auth');

const router = express.Router();
router.use(requireAuth);

const mapRow = (p) => ({
  id: p.id,
  name: p.name,
  sku: p.sku,
  price: p.price,
  stock: p.stock,
  lowStockAt: p.low_stock_at,
});

router.get('/', (req, res) => {
  res.json(db.prepare('SELECT * FROM products ORDER BY name').all().map(mapRow));
});

router.post('/', requireAdmin, (req, res) => {
  const { name, sku = '', price, stock, lowStockAt } = req.body || {};
  if (!name?.trim() || price == null || stock == null) {
    return res.status(400).json({ error: 'name, price, and stock are required.' });
  }
  const id = newId();
  db.prepare('INSERT INTO products (id, name, sku, price, stock, low_stock_at) VALUES (?,?,?,?,?,?)').run(
    id,
    name.trim(),
    (sku || '').trim(),
    Number(price),
    Number(stock),
    Number(lowStockAt ?? 5)
  );
  res.status(201).json(mapRow(db.prepare('SELECT * FROM products WHERE id = ?').get(id)));
});

router.put('/:id', requireAdmin, (req, res) => {
  const existing = db.prepare('SELECT * FROM products WHERE id = ?').get(req.params.id);
  if (!existing) return res.status(404).json({ error: 'Product not found.' });
  const { name, sku, price, stock, lowStockAt } = req.body || {};
  db.prepare('UPDATE products SET name=?, sku=?, price=?, stock=?, low_stock_at=? WHERE id=?').run(
    name?.trim() ?? existing.name,
    sku != null ? sku.trim() : existing.sku,
    price != null ? Number(price) : existing.price,
    stock != null ? Number(stock) : existing.stock,
    lowStockAt != null ? Number(lowStockAt) : existing.low_stock_at,
    req.params.id
  );
  res.json(mapRow(db.prepare('SELECT * FROM products WHERE id = ?').get(req.params.id)));
});

router.delete('/:id', requireAdmin, (req, res) => {
  const result = db.prepare('DELETE FROM products WHERE id = ?').run(req.params.id);
  if (result.changes === 0) return res.status(404).json({ error: 'Product not found.' });
  res.status(204).end();
});

module.exports = router;
