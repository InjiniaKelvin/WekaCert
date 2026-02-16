const { createServer } = require('./src/server');

const PORT = process.env.PORT || 3000;
const server = createServer();

server.listen(PORT, () => {
  console.log(`WekaCert running on http://localhost:${PORT}`);
});
