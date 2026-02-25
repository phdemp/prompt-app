const db = require('../config/database');
const config = require('../config/env');

const DAILY_LIMIT = config.limits.dailyOptimizations;

const checkDailyLimit = async (userId) => {
  const result = await db.query(
    `SELECT call_count FROM usage_logs WHERE user_id = $1 AND date = CURRENT_DATE`,
    [userId]
  );

  const usedToday = result.rows[0]?.call_count || 0;
  const remaining = Math.max(0, DAILY_LIMIT - usedToday);

  return {
    allowed: usedToday < DAILY_LIMIT,
    usedToday,
    remaining,
  };
};

const savePrompt = async (userId, rawPrompt, optimizedPrompt, tokensUsed, optimizationType) => {
  const insertResult = await db.query(
    `INSERT INTO prompts (user_id, raw_prompt, optimized_prompt, tokens_used, optimization_type)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id`,
    [userId, rawPrompt, optimizedPrompt, tokensUsed, optimizationType]
  );

  await db.query(
    `INSERT INTO usage_logs (user_id, date, call_count)
     VALUES ($1, CURRENT_DATE, 1)
     ON CONFLICT (user_id, date)
     DO UPDATE SET call_count = usage_logs.call_count + 1`,
    [userId]
  );

  return insertResult.rows[0].id;
};

const getUserPrompts = async (userId, page = 1, limit = 10) => {
  const offset = (page - 1) * limit;

  const countResult = await db.query(
    `SELECT COUNT(*) AS total FROM prompts WHERE user_id = $1`,
    [userId]
  );
  const totalCount = parseInt(countResult.rows[0].total, 10);

  const promptsResult = await db.query(
    `SELECT id, raw_prompt, optimized_prompt, tokens_used, optimization_type, created_at
     FROM prompts
     WHERE user_id = $1
     ORDER BY created_at DESC
     LIMIT $2 OFFSET $3`,
    [userId, limit, offset]
  );

  return { prompts: promptsResult.rows, totalCount };
};

const getPromptById = async (promptId, userId) => {
  const result = await db.query(
    `SELECT id, user_id, raw_prompt, optimized_prompt, tokens_used, optimization_type, created_at
     FROM prompts
     WHERE id = $1 AND user_id = $2`,
    [promptId, userId]
  );

  return result.rows[0] || null;
};

const deletePrompt = async (promptId, userId) => {
  const result = await db.query(
    `DELETE FROM prompts WHERE id = $1 AND user_id = $2 RETURNING id`,
    [promptId, userId]
  );

  return result.rowCount > 0;
};

const getTodayUsage = async (userId) => {
  const result = await db.query(
    `SELECT call_count FROM usage_logs WHERE user_id = $1 AND date = CURRENT_DATE`,
    [userId]
  );

  const usedToday = result.rows[0]?.call_count || 0;
  const remainingToday = Math.max(0, DAILY_LIMIT - usedToday);

  return { usedToday, remainingToday, maxPerDay: DAILY_LIMIT };
};

module.exports = {
  checkDailyLimit,
  savePrompt,
  getUserPrompts,
  getPromptById,
  deletePrompt,
  getTodayUsage,
};
