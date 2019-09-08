const { exec } = require('child_process');

module.exports = function shutdown(callback = () => {}) {
  exec('shutdown now', (error, stdout, stderr) => callback(stdout));
};
