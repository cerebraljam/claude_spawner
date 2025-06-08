const WebSocket = require('ws');

class TR808WebSocketServer {
  constructor(server) {
    this.wss = new WebSocket.Server({ server });
    this.clients = new Set();
    this.setupWebSocketHandling();
  }

  setupWebSocketHandling() {
    this.wss.on('connection', (ws) => {
      console.log('New client connected');
      this.clients.add(ws);

      // Send welcome message
      ws.send(JSON.stringify({
        type: 'connection',
        message: 'Connected to TR-808 Server',
        timestamp: new Date().toISOString()
      }));

      // Handle messages from client
      ws.on('message', (data) => {
        try {
          const message = JSON.parse(data.toString());
          this.handleMessage(ws, message);
        } catch (err) {
          console.error('Invalid JSON received:', err);
        }
      });

      // Handle client disconnect
      ws.on('close', () => {
        console.log('Client disconnected');
        this.clients.delete(ws);
      });

      // Handle errors
      ws.on('error', (err) => {
        console.error('WebSocket error:', err);
        this.clients.delete(ws);
      });
    });
  }

  handleMessage(ws, message) {
    switch (message.type) {
      case 'pattern_update':
        // Broadcast pattern updates to all connected clients
        this.broadcast(message, ws);
        break;
      
      case 'tempo_change':
        // Broadcast tempo changes to all connected clients
        this.broadcast(message, ws);
        break;
      
      case 'play_start':
        // Broadcast play start to all connected clients
        this.broadcast(message, ws);
        break;
      
      case 'play_stop':
        // Broadcast play stop to all connected clients
        this.broadcast(message, ws);
        break;
      
      default:
        console.log('Unknown message type:', message.type);
    }
  }

  broadcast(message, sender = null) {
    const messageString = JSON.stringify(message);
    this.clients.forEach((client) => {
      if (client !== sender && client.readyState === WebSocket.OPEN) {
        client.send(messageString);
      }
    });
  }

  close() {
    this.wss.close();
  }
}

module.exports = TR808WebSocketServer;