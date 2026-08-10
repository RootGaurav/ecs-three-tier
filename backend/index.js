const express = require('express');
const app = express();
const port = process.env.PORT || 5000;

app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.get('/api/users', (_req, res) => {
  res.json({ users: [{ id: 1, name: 'Alice' }, { id: 2, name: 'Bob' }] });
});

app.get('/api/products', (_req, res) => {
  res.json({ products: [{ id: 1, name: 'Widget' }, { id: 2, name: 'Gadget' }] });
});

app.listen(port, () => {
  console.log(`Backend listening on port ${port}`);
});
