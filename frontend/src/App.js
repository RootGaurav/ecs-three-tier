import { useEffect, useState } from 'react';

function App() {
  const [users, setUsers] = useState([]);
  const [products, setProducts] = useState([]);
  const [status, setStatus] = useState('Loading data from backend...');

  useEffect(() => {
    async function loadData() {
      try {
        const [healthRes, usersRes, productsRes] = await Promise.all([
          fetch('/api/health'),
          fetch('/api/users'),
          fetch('/api/products'),
        ]);

        const health = await healthRes.json();
        const usersData = await usersRes.json();
        const productsData = await productsRes.json();

        setUsers(usersData.users || []);
        setProducts(productsData.products || []);
        setStatus(`${health.status} - database ${health.database}`);
      } catch (err) {
        setStatus(`Failed to load data: ${err.message}`);
      }
    }

    loadData();
  }, []);

  return (
    <div style={{ fontFamily: 'sans-serif', maxWidth: '900px', margin: '0 auto', padding: '2rem' }}>
      <h1>Three-Tier App Frontend</h1>
      <p>This page is calling the backend, and the backend is reading from RDS.</p>
      <p><strong>Status:</strong> {status}</p>

      <h2>Users</h2>
      <ul>
        {users.map((user) => (
          <li key={user.id}>{user.name}</li>
        ))}
      </ul>

      <h2>Products</h2>
      <ul>
        {products.map((product) => (
          <li key={product.id}>{product.name}</li>
        ))}
      </ul>
    </div>
  );
}

export default App;
