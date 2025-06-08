// Jest setup file for TR-808 test fixes

// Set default test timeout
jest.setTimeout(10000);

// Mock console methods to reduce test noise (optional)
global.console = {
  ...console,
  // Uncomment to silence console output during tests
  // log: jest.fn(),
  // warn: jest.fn(),
  // error: jest.fn(),
};

// Global test utilities
global.waitFor = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Clean up timers after each test to prevent hanging
afterEach(() => {
  jest.clearAllTimers();
  jest.useRealTimers();
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

// Cleanup after all tests
afterAll((done) => {
  // Close any open handles, connections, etc.
  setTimeout(done, 100);
});