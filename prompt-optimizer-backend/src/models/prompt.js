const db = require('../config/database');

const create = async ({ userId, rawPrompt, optimizedPrompt, tokensUsed, optimizationType }) => {
  const result = await db.query(
    `INSERT INTO prompts (user_id, raw_prompt, optimized_prompt, tokens_used, optimization_type)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id, user_id, raw_prompt, optimized_prompt, tokens_used, optimization_type, created_at`,
    [userId, rawPrompt, optimizedPrompt, tokensUsed, optimizationType]
  );

  return result.rows[0];
};

const findById = async (id) => {
  const result = await db.query(
    `SELECT id, user_id, raw_prompt, optimized_prompt, tokens_used, optimization_type, created_at
     FROM prompts
     WHERE id = $1`,
    [id]
  );

  return result.rows[0] || null;
};

const findByUserId = async (userId, limit, offset) => {
  const result = await db.query(
    `SELECT id, raw_prompt, optimized_prompt, tokens_used, optimization_type, created_at
     FROM prompts
     WHERE user_id = $1
     ORDER BY created_at DESC
     LIMIT $2 OFFSET $3`,
    [userId, limit, offset]
  );

  return result.rows;
};

const remove = async (id, userId) => {
  const result = await db.query(
    `DELETE FROM prompts WHERE id = $1 AND user_id = $2 RETURNING id`,
    [id, userId]
  );

  return result.rowCount > 0;
};

module.exports = { create, findById, findByUserId, remove };
