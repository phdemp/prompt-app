// Load and validate env config first
const config = require('./src/config/env');

const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');

const { testConnection } = require('./src/config/database');
const { globalLimiter } = require('./src/middleware/rateLimiter');
const errorHandler = require('./src/middleware/errorHandler');

const authRouter = require('./src/routes/auth');
const optimizeRouter = require('./src/routes/optimize');
const historyRouter = require('./src/routes/history');

const app = express();

// Security & parsing middleware
app.use(helmet({ contentSecurityPolicy: false }));
app.use(
  cors({
    origin: config.cors.allowedOrigins,
    credentials: true,
  })
);
app.use(morgan('dev'));
app.use(express.json());
app.use(globalLimiter);

// Routes
app.use('/auth', authRouter);
app.use('/api', optimizeRouter);
app.use('/api', historyRouter);

// Health check
app.get('/health', async (req, res) => {
  let dbStatus = 'connected';
  try {
    const db = require('./src/config/database');
    await db.query('SELECT 1');
  } catch {
    dbStatus = 'disconnected';
  }

  res.status(200).json({
    status: 'ok',
    environment: config.nodeEnv,
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    database: dbStatus,
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: { message: `Route ${req.method} ${req.path} not found.` } });
});

// Error handler (must be last)
app.use(errorHandler);

// Start server
const start = async () => {
  await testConnection();
  app.listen(config.port, () => {
    console.log(`Server running on port ${config.port} (${config.nodeEnv})`);
  });
};

start();
