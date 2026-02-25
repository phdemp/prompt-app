const { Pool } = require('pg');
const config = require('./env');

const pool = new Pool({
  host: config.db.host,
  port: config.db.port,
  database: config.db.name,
  user: config.db.user,
  password: config.db.password,
  max: 5,
});

const query = (text, params) => pool.query(text, params);

const testConnection = async () => {
  try {
    const client = await pool.connect();
    client.release();
    console.log('Database connected successfully');
  } catch (err) {
    console.error('Failed to connect to database:', err.message);
    process.exit(1);
  }
};

module.exports = { query, testConnection };
