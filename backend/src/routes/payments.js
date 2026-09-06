const express = require('express');
const db = require('../db');
const { requireAuth } = require('../auth');

const router = express.Router();
router.use(requireAuth);

router.get('/', (req, res) => {
  const rows = db.prepare('SELECT id, customer_id as customerId, amount, date FROM payments ORDER BY date DESC').all();
  res.json(rows);
});

module.exports = router;
