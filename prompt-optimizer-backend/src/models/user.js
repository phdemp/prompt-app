const db = require('../config/database');

const upsertUser = async ({ googleId, email, displayName, picture }) => {
  const result = await db.query(
    `INSERT INTO users (google_id, email, display_name, picture)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (google_id)
     DO UPDATE SET
       last_login = NOW(),
       display_name = EXCLUDED.display_name,
       picture = EXCLUDED.picture
     RETURNING id, google_id, email, display_name, picture, created_at, last_login`,
    [googleId, email, displayName, picture]
  );

  return result.rows[0];
};

const findUserById = async (id) => {
  const result = await db.query(
    `SELECT id, google_id, email, display_name, picture, created_at, last_login
     FROM users
     WHERE id = $1`,
    [id]
  );

  return result.rows[0] || null;
};

module.exports = { upsertUser, findUserById };
