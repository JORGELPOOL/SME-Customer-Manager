const express = require('express');
const db = require('../db');
const { requireAuth, requireAdmin } = require('../auth');

const router = express.Router();
router.use(requireAuth, requireAdmin);

function weekBuckets(rows, valueKey) {
  const buckets = new Array(8).fill(0);
  const now = Date.now();
  for (const row of rows) {
    const d = new Date(row.date).getTime();
    if (Number.isNaN(d)) continue;
    const days = Math.floor((now - d) / 86400000);
    const bucketFromEnd = Math.min(7, Math.max(0, Math.floor(days / 7)));
    const idx = 7 - bucketFromEnd;
    buckets[idx] += row[valueKey];
  }
  return buckets.map((v) => Math.round(v * 100) / 100);
}

router.get('/summary', (req, res) => {
  const transactions = db.prepare('SELECT amount_paid as value, date FROM transactions').all();
  const payments = db.prepare('SELECT amount as value, date FROM payments').all();
  const expenses = db.prepare('SELECT amount as value, category, date FROM expenses').all();

  const totalRevenue = transactions.reduce((s, t) => s + t.value, 0) + payments.reduce((s, p) => s + p.value, 0);
  const totalExpenses = expenses.reduce((s, e) => s + e.value, 0);

  // Revenue buckets should reflect money actually collected, so combine
  // amount-paid-at-sale with any later standalone payments.
  const revenueByWeek = weekBuckets([...transactions, ...payments], 'value');
  const expensesByWeek = weekBuckets(expenses, 'value');

  const byCategory = {};
  for (const e of expenses) byCategory[e.category] = Math.round(((byCategory[e.category] || 0) + e.value) * 100) / 100;

  res.json({
    totalRevenue: Math.round(totalRevenue * 100) / 100,
    totalExpenses: Math.round(totalExpenses * 100) / 100,
    estimatedProfit: Math.round((totalRevenue - totalExpenses) * 100) / 100,
    revenueByWeek,
    expensesByWeek,
    expensesByCategory: byCategory,
  });
});

module.exports = router;
