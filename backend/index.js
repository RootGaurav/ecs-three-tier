const express = require('express');
const pool = require('./db');

const app = express();
const port = process.env.PORT || 5000;

async function seedDatabase() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL
    )
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS products (
      id SERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL
    )
  `);

  const userCount = await pool.query('SELECT COUNT(*)::int AS count FROM users');
  if (userCount.rows[0].count === 0) {
    await pool.query(
      'INSERT INTO users (name) VALUES ($1), ($2), ($3)',
      ['Alice', 'Bob', 'Charlie']
    );
  }

  const productCount = await pool.query('SELECT COUNT(*)::int AS count FROM products');
  if (productCount.rows[0].count === 0) {
    await pool.query(
      'INSERT INTO products (name) VALUES ($1), ($2), ($3)',
      ['Widget', 'Gadget', 'Thingamajig']
    );
  }
}

app.get('/api/health', async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({
      status: 'ok',
      database: 'connected',
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    res.status(500).json({
      status: 'failed',
      database: 'disconnected',
      error: err.message,
    });
  }
});

app.get('/api/users', async (_req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, name FROM users ORDER BY id ASC'
    );

    res.json({ users: result.rows });
  } catch (err) {
    res.status(500).json({
      error: 'Failed to fetch users',
      details: err.message,
    });
  }
});

app.get('/api/products', async (_req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, name FROM products ORDER BY id ASC'
    );

    res.json({ products: result.rows });
  } catch (err) {
    res.status(500).json({
      error: 'Failed to fetch products',
      details: err.message,
    });
  }
});

async function start() {
  try {
    await seedDatabase();
    app.listen(port, () => {
      console.log(`Backend listening on port ${port}`);
    });
  } catch (err) {
    console.error('Failed to initialize backend:', err);
    process.exit(1);
  }
}

start();
