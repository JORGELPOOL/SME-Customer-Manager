const express = require('express');
const db = require('../db');
const { requireAuth, requireAdmin } = require('../auth');

const router = express.Router();

router.get('/', requireAuth, (req, res) => {
  res.json(db.prepare('SELECT name, currency FROM business WHERE id = 1').get());
});

router.put('/', requireAuth, requireAdmin, (req, res) => {
  const { name } = req.body || {};
  if (!name || !name.trim()) return res.status(400).json({ error: 'Business name is required.' });
  db.prepare('UPDATE business SET name = ? WHERE id = 1').run(name.trim());
  res.json(db.prepare('SELECT name, currency FROM business WHERE id = 1').get());
});

module.exports = router;
