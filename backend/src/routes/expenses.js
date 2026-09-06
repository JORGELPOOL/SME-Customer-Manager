const express = require('express');
const db = require('../db');
const { newId } = require('../utils');
const { requireAuth, requireAdmin } = require('../auth');
const { expenseCategories } = require('../constants');

const router = express.Router();
router.use(requireAuth, requireAdmin);

router.get('/', (req, res) => {
  const rows = db.prepare('SELECT * FROM expenses ORDER BY date DESC').all();
  res.json(
    rows.map((e) => ({
      id: e.id,
      category: e.category,
      amount: e.amount,
      date: e.date,
      note: e.note,
      recordedBy: e.recorded_by,
    }))
  );
});

router.get('/meta/categories', (req, res) => res.json(expenseCategories));

router.post('/', (req, res) => {
  const { category, amount, date, note = '' } = req.body || {};
  const amt = Number(amount);
  if (!category || !amt || amt <= 0 || !date) {
    return res.status(400).json({ error: 'category, a positive amount, and date are required.' });
  }
  const id = newId();
  db.prepare('INSERT INTO expenses (id, category, amount, date, note, recorded_by) VALUES (?,?,?,?,?,?)').run(
    id,
    category,
    amt,
    date,
    (note || '').trim(),
    req.user.name
  );
  res.status(201).json({ id, category, amount: amt, date, note: (note || '').trim(), recordedBy: req.user.name });
});

router.delete('/:id', (req, res) => {
  const result = db.prepare('DELETE FROM expenses WHERE id = ?').run(req.params.id);
  if (result.changes === 0) return res.status(404).json({ error: 'Expense not found.' });
  res.status(204).end();
});

module.exports = router;
