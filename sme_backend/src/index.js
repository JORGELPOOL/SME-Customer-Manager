require('dotenv').config();

// Fail fast and clearly if the server is misconfigured, rather than starting
// up in a broken state that's confusing to debug later.
if (!process.env.JWT_SECRET || process.env.JWT_SECRET === 'change_this_to_a_long_random_string') {
  console.error(
    'JWT_SECRET is missing or still set to the placeholder value.\n' +
      'Set a real secret in your .env file before starting the server, e.g.:\n' +
      '  node -e "console.log(require(\'crypto\').randomBytes(48).toString(\'hex\'))"'
  );
  process.exit(1);
}

const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const authRoutes = require('./routes/auth');
const businessRoutes = require('./routes/business');
const staffRoutes = require('./routes/staff');
const customerRoutes = require('./routes/customers');
const productRoutes = require('./routes/products');
const transactionRoutes = require('./routes/transactions');
const supplierRoutes = require('./routes/suppliers');
const paymentRoutes = require('./routes/payments');
const expenseRoutes = require('./routes/expenses');
const reportRoutes = require('./routes/reports');
const backupRoutes = require('./routes/backup');

const app = express();

const corsOrigin = process.env.CORS_ORIGIN || '*';
app.use(cors({ origin: corsOrigin === '*' ? true : corsOrigin.split(',').map((s) => s.trim()) }));

app.use(express.json());

// Malformed JSON bodies should be a clean 400, not a generic 500.
app.use((err, req, res, next) => {
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ error: 'Malformed JSON in request body.' });
  }
  next(err);
});

app.get('/api/health', (req, res) => res.json({ status: 'ok', time: new Date().toISOString() }));

// Slow down brute-force login attempts without needing an external service.
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many login attempts. Please wait a few minutes and try again.' },
});
app.use('/api/auth/login', loginLimiter);

app.use('/api/auth', authRoutes);
app.use('/api/business', businessRoutes);
app.use('/api/staff', staffRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/products', productRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/suppliers', supplierRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/expenses', expenseRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/backup', backupRoutes);

app.use((req, res) => res.status(404).json({ error: 'Not found.' }));

// Final catch-all error handler.
app.use((err, req, res, next) => {
  console.error(err);
  res.status(err.status || 500).json({ error: err.message || 'Internal server error.' });
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`SME backend listening on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/api/health`);
});
