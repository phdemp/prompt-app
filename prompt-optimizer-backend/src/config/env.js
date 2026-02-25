const dotenv = require('dotenv');
dotenv.config();

const required = [
  'JWT_SECRET',
  'GOOGLE_CLIENT_ID',
  'OPENAI_API_KEY',
  'DB_NAME',
  'DB_USER',
  'DB_PASSWORD',
];

for (const key of required) {
  if (!process.env[key]) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
}

const config = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT, 10) || 3000,

  db: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT, 10) || 5432,
    name: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
  },

  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  },

  google: {
    clientId: process.env.GOOGLE_CLIENT_ID,
  },

  openai: {
    apiKey: process.env.OPENAI_API_KEY,
  },

  cors: {
    allowedOrigins: (process.env.ALLOWED_ORIGINS || 'http://localhost:3000')
      .split(',')
      .map((o) => o.trim()),
  },

  limits: {
    dailyOptimizations: parseInt(process.env.DAILY_OPTIMIZATION_LIMIT, 10) || 100,
  },
};

module.exports = config;
