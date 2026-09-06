# SME Customer Manager — Backend

A small Node.js/Express + SQLite API that gives the SME Customer Manager app a single shared
source of truth, so multiple devices/browsers (or several staff phones) see the same customers,
sales, debt, inventory, suppliers, expenses, and staff accounts — instead of each device having
its own local copy.

Replaces the previous local-only, plaintext-password login with real password hashing (bcrypt)
and short-lived JWT sessions.

## Tech stack

- **Express** — HTTP API
- **better-sqlite3** — single-file database, no external DB server to run
- **bcryptjs** — password hashing
- **jsonwebtoken** — session tokens
- **express-rate-limit** — basic brute-force protection on login

SQLite is deliberately chosen here: for a single small business, it's zero-ops (one file, easy to
back up, no separate database server to run or pay for). If you outgrow a single server instance —
e.g. deploying across multiple regions or serverless functions — see **Scaling beyond SQLite**
below for the upgrade path to Postgres.

## Setup

```bash
cd sme_backend
npm install
cp .env.example .env
```

Open `.env` and set a real `JWT_SECRET`:

```bash
node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
```

Paste the output in as `JWT_SECRET=...`. The server refuses to start with the placeholder value,
on purpose.

Start it:

```bash
npm run dev     # auto-restarts on file changes, for local development
# or
npm start       # plain node, for production
```

You should see:

```
Seeded default admin account -> username: admin / password: admin123 (change this immediately).
SME backend listening on port 4000
Health check: http://localhost:4000/api/health
```

Optionally load sample data (customers, products, a few sales) to explore with:

```bash
npm run seed
```

## Quick test with curl

```bash
# Log in
curl -s -X POST http://localhost:4000/api/health

curl -s -X POST http://localhost:4000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
# -> { "token": "...", "user": { ... } }

# Use the token on any other route
TOKEN="paste the token here"
curl -s http://localhost:4000/api/customers -H "Authorization: Bearer $TOKEN"
```

## Authentication

`POST /api/auth/login` returns a JWT valid for 12 hours. Send it on every other request as:

```
Authorization: Bearer <token>
```

`GET /api/auth/me` returns the account tied to the current token — useful for restoring a session
after an app restart without asking for the password again.

There's no server-side logout endpoint (JWTs are stateless) — the client just discards the token.

## Role model

Every route below marked **admin** rejects non-admin tokens with `403`. This mirrors the roles in
the Flutter app:

| Area                    | Staff | Admin |
|--------------------------|-------|-------|
| Read customers/inventory/suppliers | ✅ | ✅ |
| Add customers, record payments/sales | ✅ | ✅ |
| Delete customers          | ❌    | ✅    |
| Create/edit/delete products | ❌  | ✅    |
| Create/edit/delete suppliers | ❌ | ✅   |
| Expenses (all actions)    | ❌    | ✅    |
| Reports                   | ❌    | ✅    |
| Staff accounts            | ❌    | ✅    |
| Business profile update   | ❌    | ✅    |
| Backup export              | ❌    | ✅    |

## API reference

All paths are prefixed with `/api`. All routes except `/health` and `/auth/login` require a
bearer token.

### Auth
- `POST /auth/login` — `{ username, password }` → `{ token, user }`
- `GET /auth/me` → `{ user }`

### Business
- `GET /business` → `{ name, currency }`
- `PUT /business` *(admin)* — `{ name }`

### Staff
- `GET /staff` *(admin)* → list of `{ id, name, username, role }`
- `POST /staff` *(admin)* — `{ name, username, password, role }` → `409` if username is taken
- `DELETE /staff/:id` *(admin)* — blocked if it's your own account, or the last remaining admin

### Customers
- `GET /customers` → list with computed `balance` and `purchaseCount`
- `GET /customers/:id` → full detail with `transactions[]`, `payments[]`, `balance`
- `POST /customers` — `{ name, phone }`
- `DELETE /customers/:id` *(admin)*
- `POST /customers/:id/payments` — `{ amount }` → records a standalone payment against debt
- `POST /customers/:id/remind` → stamps `lastReminded` with today's date

### Products (inventory)
- `GET /products`
- `POST /products` *(admin)* — `{ name, sku?, price, stock, lowStockAt? }`
- `PUT /products/:id` *(admin)* — partial updates supported
- `DELETE /products/:id` *(admin)*

### Transactions (sales)
- `GET /transactions` — optional `?customerId=` or `?limit=`
- `POST /transactions` — `{ customerId, items: [{ productId, qty }], amountPaid }`
  - Server looks up current product prices, computes the total, checks stock (`409` if
    insufficient), deducts stock, and derives `status` (`paid` / `partial` / `unpaid`) — all in one
    database transaction so a sale can't be recorded with stock left inconsistent.

### Suppliers
- `GET /suppliers`
- `POST /suppliers` *(admin)* — `{ name, phone?, suppliesWhat?, notes? }`
- `PUT /suppliers/:id` *(admin)*
- `DELETE /suppliers/:id` *(admin)*

### Expenses *(admin only for all of these)*
- `GET /expenses`
- `GET /expenses/meta/categories` → suggested category list
- `POST /expenses` — `{ category, amount, date, note? }`
- `DELETE /expenses/:id`

### Reports *(admin only)*
- `GET /reports/summary` → `{ totalRevenue, totalExpenses, estimatedProfit, revenueByWeek[8], expensesByWeek[8], expensesByCategory }`

### Payments (flat list, used by the Flutter client for debt calculations)
- `GET /payments` → all payments across every customer

### Backup *(admin only)*
- `GET /backup` → full JSON dump (`business`, `staff` *(no password hashes)*, `customers`,
  `inventory`, `transactions`, `payments`, `suppliers`, `expenses`), sent with a
  `Content-Disposition` header so a browser treats it as a file download.

### Health
- `GET /health` → `{ status: "ok", time }` — no auth required, useful for uptime checks.

## Security notes

- Change the seeded `admin` / `admin123` login immediately after first deploy.
- Set a strong, unique `JWT_SECRET` per environment — never reuse the example value.
- Put the server behind HTTPS in production (most hosts terminate TLS for you automatically).
- Restrict `CORS_ORIGIN` to your actual app's domain(s) once you're past local development;
  `*` is fine for development only.
- Passwords are hashed with bcrypt before storage — they are never stored or logged in plain text.

## Deploying

This is a plain Node process — it runs on any host that can run `npm install && npm start`:
Render, Railway, Fly.io, a small VPS with `pm2`, etc.

The one thing to get right: **`DB_PATH` must point at persistent disk.** SQLite is a single file;
if your host wipes the filesystem between deploys or restarts (common on serverless/ephemeral
platforms), point `DB_PATH` at a mounted persistent volume, or the database will appear to "reset"
after every deploy.

## Scaling beyond SQLite

SQLite comfortably handles a single small business's traffic on a single server. If you later need
multiple server instances behind a load balancer (horizontal scaling, or a serverless platform with
no persistent disk), swap `better-sqlite3` for a `pg` (Postgres) client — the route files are thin
wrappers around SQL statements, so the rewrite is mechanical: replace `db.prepare(...).get()/.all()/.run()`
calls with equivalent `pg` queries, and change the table `CREATE` statements in `db.js` to Postgres
syntax (mainly: `AUTOINCREMENT` → `SERIAL`/`IDENTITY`). The route logic, auth, and validation stay
the same.

## Project structure

```
src/
  index.js           entry point, middleware, route mounting, startup checks
  db.js              SQLite connection, schema, default admin seeding
  auth.js            JWT signing + requireAuth/requireAdmin middleware
  utils.js           id generator, date helper
  constants.js        expense category list
  seed.js            optional sample-data loader
  routes/
    auth.js
    business.js
    staff.js
    customers.js
    products.js
    transactions.js
    suppliers.js
    expenses.js
    reports.js
    backup.js
```

## Connecting the Flutter app

The companion Flutter app (`sme_customer_manager`) is now wired up to this backend — see its
README for setup and local-network notes (Android emulator, physical devices, etc. all need
different server URLs than `localhost`).
