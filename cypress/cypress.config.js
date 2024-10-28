const { defineConfig } = require('cypress');

module.exports = defineConfig({
  e2e: {
    setupNodeEvents(on, config) {
      require('@cypress/code-coverage/task')(on, config);
      return config;
    },
    specPattern: 'integration/**/*.{js,jsx,ts,tsx}',
    baseUrl: 'http://localhost:3000',
    supportFile: false,
    video: false,
    screenshotOnRunFailure: false,
    defaultCommandTimeout: 10000,
    pageLoadTimeout: 10000,
    responseTimeout: 10000,
    requestTimeout: 10000,
  },
});