const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../db');
const { signToken, requireAuth } = require('../auth');

const router = express.Router();

router.post('/login', (req, res) => {
  const { username, password } = req.body || {};
  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password are required.' });
  }
  const staff = db.prepare('SELECT * FROM staff WHERE lower(username) = lower(?)').get(String(username).trim());
  if (!staff || !bcrypt.compareSync(password, staff.password_hash)) {
    return res.status(401).json({ error: 'Incorrect username or password.' });
  }
  const token = signToken(staff);
  res.json({
    token,
    user: { id: staff.id, name: staff.name, username: staff.username, role: staff.role },
  });
});

router.get('/me', requireAuth, (req, res) => {
  res.json({ user: req.user });
});

module.exports = router;
