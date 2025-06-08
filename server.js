const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const http = require('http');
const TR808WebSocketServer = require('./websocket');

const app = express();
const server = http.createServer(app);
const PORT = process.env.PORT || 3000;

// Initialize WebSocket server
let wsServer;

// Middleware
app.use(cors());
app.use(express.json());

// Create public directory if it doesn't exist
const publicDir = path.join(__dirname, 'public');
if (!fs.existsSync(publicDir)) {
  fs.mkdirSync(publicDir, { recursive: true });
}

// Serve static files from public directory
app.use(express.static(publicDir));

// API endpoints
app.get('/api/status', (req, res) => {
  res.json({ 
    status: 'TR-808 Server Running',
    timestamp: new Date().toISOString()
  });
});

// Serve main HTML file for root route
app.get('/', (req, res) => {
  const indexPath = path.join(publicDir, 'index.html');
  
  // Create a basic index.html if it doesn't exist
  if (!fs.existsSync(indexPath)) {
    const basicHTML = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TR-808 Drum Machine</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <h1>Roland TR-808 Drum Machine</h1>
    <p>Virtual TR-808 interface coming soon...</p>
    <script src="app.js"></script>
</body>
</html>`;
    fs.writeFileSync(indexPath, basicHTML);
  }
  
  res.sendFile(indexPath);
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// Only start server if not in test environment
if (require.main === module) {
  server.listen(PORT, () => {
    console.log(`TR-808 Server running on http://localhost:${PORT}`);
    // Initialize WebSocket server after HTTP server starts
    wsServer = new TR808WebSocketServer(server);
  });
}

module.exports = app;