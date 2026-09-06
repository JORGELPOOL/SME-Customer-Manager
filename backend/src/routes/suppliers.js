const express = require('express');
const db = require('../db');
const { newId, todayIso } = require('../utils');
const { requireAuth, requireAdmin } = require('../auth');

const router = express.Router();
router.use(requireAuth);

const mapRow = (s) => ({
  id: s.id,
  name: s.name,
  phone: s.phone,
  suppliesWhat: s.supplies_what,
  notes: s.notes,
  createdAt: s.created_at,
});

router.get('/', (req, res) => {
  res.json(db.prepare('SELECT * FROM suppliers ORDER BY name').all().map(mapRow));
});

router.post('/', requireAdmin, (req, res) => {
  const { name, phone = '', suppliesWhat = '', notes = '' } = req.body || {};
  if (!name?.trim()) return res.status(400).json({ error: 'name is required.' });
  const id = newId();
  db.prepare('INSERT INTO suppliers (id, name, phone, supplies_what, notes, created_at) VALUES (?,?,?,?,?,?)').run(
    id,
    name.trim(),
    (phone || '').trim(),
    (suppliesWhat || '').trim(),
    (notes || '').trim(),
    todayIso()
  );
  res.status(201).json(mapRow(db.prepare('SELECT * FROM suppliers WHERE id = ?').get(id)));
});

router.put('/:id', requireAdmin, (req, res) => {
  const existing = db.prepare('SELECT * FROM suppliers WHERE id = ?').get(req.params.id);
  if (!existing) return res.status(404).json({ error: 'Supplier not found.' });
  const { name, phone, suppliesWhat, notes } = req.body || {};
  db.prepare('UPDATE suppliers SET name=?, phone=?, supplies_what=?, notes=? WHERE id=?').run(
    name?.trim() ?? existing.name,
    phone != null ? phone.trim() : existing.phone,
    suppliesWhat != null ? suppliesWhat.trim() : existing.supplies_what,
    notes != null ? notes.trim() : existing.notes,
    req.params.id
  );
  res.json(mapRow(db.prepare('SELECT * FROM suppliers WHERE id = ?').get(req.params.id)));
});

router.delete('/:id', requireAdmin, (req, res) => {
  const result = db.prepare('DELETE FROM suppliers WHERE id = ?').run(req.params.id);
  if (result.changes === 0) return res.status(404).json({ error: 'Supplier not found.' });
  res.status(204).end();
});

module.exports = router;
