import React from 'react';

function App() {
  return (
    <div style={{ fontFamily: 'sans-serif', textAlign: 'center', padding: '2rem' }}>
      <h1>Three-Tier App Frontend</h1>
      <p>This is the React frontend served by Nginx on ECS.</p>
      <p>API health check: <code>/api/health</code></p>
    </div>
  );
}

export default App;
