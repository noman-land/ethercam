module.exports = function Cleanup(callback = () => {}) {
  process.on('cleanup', callback);

  process.on('exit', () => {
    process.emit('cleanup');
  });

  process.on('SIGINT', () => {
    console.log('Ctrl-C...');
    process.exit(2);
  });

  process.on('SIGUSR2', () => {
    console.log('Killed by nodemon');
    process.exit(2);
  });

  process.on('uncaughtException', e => {
    console.log('Uncaught Exception...');
    console.log(e.stack);
    process.exit(99);
  });
};
