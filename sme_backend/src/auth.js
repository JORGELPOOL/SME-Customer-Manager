const jwt = require('jsonwebtoken');
const db = require('./db');

const JWT_SECRET = process.env.JWT_SECRET;
const TOKEN_EXPIRY = '12h';

function signToken(staff) {
  return jwt.sign({ id: staff.id, role: staff.role }, JWT_SECRET, { expiresIn: TOKEN_EXPIRY });
}

function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Missing or invalid Authorization header.' });
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    const staff = db.prepare('SELECT id, name, username, role FROM staff WHERE id = ?').get(payload.id);
    if (!staff) return res.status(401).json({ error: 'This account no longer exists.' });
    req.user = staff;
    next();
  } catch (e) {
    return res.status(401).json({ error: 'Invalid or expired session. Please sign in again.' });
  }
}

function requireAdmin(req, res, next) {
  if (req.user?.role !== 'admin') return res.status(403).json({ error: 'Admin access is required for this action.' });
  next();
}

module.exports = { signToken, requireAuth, requireAdmin };
