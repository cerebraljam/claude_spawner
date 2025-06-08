const request = require('supertest');
const path = require('path');

describe('TR-808 Express Server', () => {
  let app;
  let server;

  beforeEach(() => {
    // Reset module cache to get fresh server instance
    delete require.cache[require.resolve('./server.js')];
    app = require('./server.js');
  });

  afterEach(async () => {
    // Properly close server and any open connections
    if (server && server.listening) {
      await new Promise((resolve) => {
        server.close(() => {
          resolve();
        });
      });
    }
    
    // Clear any intervals/timeouts
    jest.clearAllTimers();
  });

  test('should respond to GET /', async () => {
    const response = await request(app).get('/');
    expect(response.status).toBe(200);
    expect(response.type).toBe('text/html');
  });

  test('should serve static files from public directory', async () => {
    const response = await request(app).get('/style.css');
    expect(response.status).toBe(200);
  });

  test('should handle 404 for non-existent routes', async () => {
    const response = await request(app).get('/non-existent');
    expect(response.status).toBe(404);
  });

  test('should have CORS enabled', async () => {
    const response = await request(app).get('/');
    expect(response.headers['access-control-allow-origin']).toBeDefined();
  });

  test('should serve JSON content type for API endpoints', async () => {
    const response = await request(app).get('/api/status');
    expect(response.status).toBe(200);
    expect(response.type).toBe('application/json');
    expect(response.body).toHaveProperty('status');
  });
});