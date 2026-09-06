const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../db');
const { newId, todayIso } = require('../utils');
const { requireAuth, requireAdmin } = require('../auth');

const router = express.Router();
router.use(requireAuth, requireAdmin);

router.get('/', (req, res) => {
  res.json(db.prepare('SELECT id, name, username, role FROM staff ORDER BY created_at').all());
});

router.post('/', (req, res) => {
  const { name, username, password, role } = req.body || {};
  if (!name?.trim() || !username?.trim() || !password || !['admin', 'staff'].includes(role)) {
    return res.status(400).json({ error: 'name, username, password, and a valid role are required.' });
  }
  const exists = db.prepare('SELECT id FROM staff WHERE lower(username) = lower(?)').get(username.trim());
  if (exists) return res.status(409).json({ error: 'That username is already taken.' });

  const id = newId();
  const hash = bcrypt.hashSync(password, 10);
  db.prepare(
    'INSERT INTO staff (id, name, username, password_hash, role, created_at) VALUES (?,?,?,?,?,?)'
  ).run(id, name.trim(), username.trim(), hash, role, todayIso());

  res.status(201).json({ id, name: name.trim(), username: username.trim(), role });
});

router.delete('/:id', (req, res) => {
  const target = db.prepare('SELECT * FROM staff WHERE id = ?').get(req.params.id);
  if (!target) return res.status(404).json({ error: 'Staff account not found.' });
  if (target.id === req.user.id) return res.status(400).json({ error: 'You cannot remove your own account.' });
  if (target.role === 'admin') {
    const adminCount = db.prepare("SELECT COUNT(*) as c FROM staff WHERE role = 'admin'").get().c;
    if (adminCount <= 1) return res.status(400).json({ error: 'At least one admin account must remain.' });
  }
  db.prepare('DELETE FROM staff WHERE id = ?').run(req.params.id);
  res.status(204).end();
});

module.exports = router;
