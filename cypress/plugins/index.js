const codeCoverageTask = require('@cypress/code-coverage/task');

module.exports = (on, config) => {
  codeCoverageTask(on, config);
  return config;
};