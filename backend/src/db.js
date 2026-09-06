const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');
const bcrypt = require('bcryptjs');
const { newId, todayIso } = require('./utils');

const DB_PATH = process.env.DB_PATH || path.join(__dirname, '..', 'data', 'sme.db');
fs.mkdirSync(path.dirname(DB_PATH), { recursive: true });

const db = new Database(DB_PATH);
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

db.exec(`
  CREATE TABLE IF NOT EXISTS business (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    name TEXT NOT NULL,
    currency TEXT NOT NULL DEFAULT 'GH₵'
  );

  CREATE TABLE IF NOT EXISTS staff (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin','staff')),
    created_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS customers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    created_at TEXT NOT NULL,
    last_reminded TEXT
  );

  CREATE TABLE IF NOT EXISTS products (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    sku TEXT,
    price REAL NOT NULL DEFAULT 0,
    stock INTEGER NOT NULL DEFAULT 0,
    low_stock_at INTEGER NOT NULL DEFAULT 5
  );

  CREATE TABLE IF NOT EXISTS transactions (
    id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    total REAL NOT NULL,
    amount_paid REAL NOT NULL,
    date TEXT NOT NULL,
    status TEXT NOT NULL,
    recorded_by TEXT
  );

  CREATE TABLE IF NOT EXISTS transaction_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    transaction_id TEXT NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    product_id TEXT,
    name TEXT NOT NULL,
    qty INTEGER NOT NULL,
    price REAL NOT NULL
  );

  CREATE TABLE IF NOT EXISTS payments (
    id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    amount REAL NOT NULL,
    date TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS suppliers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT,
    supplies_what TEXT,
    notes TEXT,
    created_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS expenses (
    id TEXT PRIMARY KEY,
    category TEXT NOT NULL,
    amount REAL NOT NULL,
    date TEXT NOT NULL,
    note TEXT,
    recorded_by TEXT
  );

  CREATE INDEX IF NOT EXISTS idx_transactions_customer ON transactions(customer_id);
  CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date);
  CREATE INDEX IF NOT EXISTS idx_payments_customer ON payments(customer_id);
  CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date);
`);

// Seed the single business row.
const bizRow = db.prepare('SELECT id FROM business WHERE id = 1').get();
if (!bizRow) {
  db.prepare('INSERT INTO business (id, name, currency) VALUES (1, ?, ?)').run('My Business', 'GH₵');
}

// Seed a default admin account the very first time the database is created,
// so there is always a way to log in.
const staffCount = db.prepare('SELECT COUNT(*) as c FROM staff').get().c;
if (staffCount === 0) {
  const hash = bcrypt.hashSync('admin123', 10);
  db.prepare(
    'INSERT INTO staff (id, name, username, password_hash, role, created_at) VALUES (?,?,?,?,?,?)'
  ).run(newId(), 'Admin User', 'admin', hash, 'admin', todayIso());
  console.log('Seeded default admin account -> username: admin / password: admin123 (change this immediately).');
}

module.exports = db;
