module.exports = {
  // Use node environment for all tests
  testEnvironment: 'node',
  
  // Increase test timeout to prevent hanging tests
  testTimeout: 10000, // 10 seconds
  
  // Setup files to run before tests
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  
  // Configure Jest to handle Node.js module resolution
  
  // Clear mocks between tests
  clearMocks: true,
  
  // Collect coverage from relevant files
  collectCoverageFrom: [
    'public/**/*.js',
    'server.js',
    '!public/**/*.test.js',
    '!public/**/*.spec.js'
  ],
  
  // Test file patterns
  testMatch: [
    '**/__tests__/**/*.(js|jsx|ts|tsx)',
    '**/*.(test|spec).(js|jsx|ts|tsx)'
  ],
  
  // Transform configuration for ES modules and other file types
  transform: {
    '^.+\\.(js|jsx)$': 'babel-jest'
  },
  
  // Module file extensions
  moduleFileExtensions: ['js', 'jsx', 'json'],
  
  // Ignore patterns
  testPathIgnorePatterns: [
    '/node_modules/',
    '/public/node_modules/'
  ],
  
  // Verbose output
  verbose: true,
  
  // Force exit to handle hanging processes
  forceExit: true
};