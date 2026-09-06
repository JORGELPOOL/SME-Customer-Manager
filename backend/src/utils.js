function newId() {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 10);
}

function todayIso() {
  return new Date().toISOString().slice(0, 10);
}

module.exports = { newId, todayIso };
