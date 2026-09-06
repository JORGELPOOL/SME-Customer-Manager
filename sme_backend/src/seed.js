require('dotenv').config();
const db = require('./db');
const { newId } = require('./utils');

function daysAgo(n) {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d.toISOString().slice(0, 10);
}

const existingCustomers = db.prepare('SELECT COUNT(*) as c FROM customers').get().c;
if (existingCustomers > 0) {
  console.log('Database already has customers — skipping seed to avoid duplicating data.');
  console.log('Delete the .db file (or use a fresh DB_PATH) if you want to reseed from scratch.');
  process.exit(0);
}

const c1 = newId(), c2 = newId(), c3 = newId();
const insertCustomer = db.prepare('INSERT INTO customers (id,name,phone,created_at) VALUES (?,?,?,?)');
insertCustomer.run(c1, 'Ama Boateng', '024 555 1122', daysAgo(60));
insertCustomer.run(c2, 'Kwame Owusu', '020 333 8899', daysAgo(50));
insertCustomer.run(c3, 'Efua Mensah', '055 777 2244', daysAgo(30));

const p1 = newId(), p2 = newId(), p3 = newId(), p4 = newId();
const insertProduct = db.prepare('INSERT INTO products (id,name,sku,price,stock,low_stock_at) VALUES (?,?,?,?,?,?)');
insertProduct.run(p1, 'Bag of Rice (25kg)', 'RICE-25', 380, 14, 5);
insertProduct.run(p2, 'Cooking Oil (5L)', 'OIL-5L', 120, 3, 5);
insertProduct.run(p3, 'Bar Soap (dozen)', 'SOAP-12', 60, 22, 8);
insertProduct.run(p4, 'Sachet Water (bag)', 'WATER-BAG', 8, 40, 15);

const insertSupplier = db.prepare('INSERT INTO suppliers (id,name,phone,supplies_what,notes,created_at) VALUES (?,?,?,?,?,?)');
insertSupplier.run(newId(), 'Golden Grains Ltd', '030 222 4411', 'Rice, grains', 'Delivers every Monday', daysAgo(90));
insertSupplier.run(newId(), 'Coastal Oils & Soap', '024 888 1200', 'Cooking oil, soap', 'Requires 3 days notice', daysAgo(75));

const insertExpense = db.prepare('INSERT INTO expenses (id,category,amount,date,note,recorded_by) VALUES (?,?,?,?,?,?)');
insertExpense.run(newId(), 'Rent', 800, daysAgo(25), 'Shop rent', 'Admin User');
insertExpense.run(newId(), 'Transport', 60, daysAgo(10), 'Delivery van fuel', 'Admin User');
insertExpense.run(newId(), 'Utilities', 150, daysAgo(5), 'Electricity bill', 'Admin User');

const insertTx = db.prepare('INSERT INTO transactions (id,customer_id,total,amount_paid,date,status,recorded_by) VALUES (?,?,?,?,?,?,?)');
const insertItem = db.prepare('INSERT INTO transaction_items (transaction_id, product_id, name, qty, price) VALUES (?,?,?,?,?)');
const updateStock = db.prepare('UPDATE products SET stock = stock - ? WHERE id = ?');

function sale(customerId, items, days, paidRatio) {
  const total = items.reduce((s, it) => s + it.qty * it.price, 0);
  const paid = Math.round(total * paidRatio);
  const status = paid >= total ? 'paid' : paid > 0 ? 'partial' : 'unpaid';
  const id = newId();
  insertTx.run(id, customerId, total, paid, daysAgo(days), status, 'Admin User');
  for (const it of items) {
    insertItem.run(id, it.productId, it.name, it.qty, it.price);
    updateStock.run(it.qty, it.productId);
  }
}

sale(c1, [{ productId: p1, name: 'Bag of Rice (25kg)', qty: 1, price: 380 }], 20, 1);
sale(c1, [{ productId: p2, name: 'Cooking Oil (5L)', qty: 2, price: 120 }], 8, 0.5);
sale(c2, [{ productId: p3, name: 'Bar Soap (dozen)', qty: 3, price: 60 }], 15, 0);
sale(c2, [{ productId: p4, name: 'Sachet Water (bag)', qty: 5, price: 8 }], 3, 1);
sale(c3, [{ productId: p1, name: 'Bag of Rice (25kg)', qty: 2, price: 380 }], 30, 0.25);

console.log('Sample data inserted: 3 customers, 4 products, 2 suppliers, 3 expenses, 5 sales.');
