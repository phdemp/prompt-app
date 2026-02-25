const express = require('express');
const verifyJWT = require('../middleware/verifyJWT');
const { optimizeLimiter } = require('../middleware/rateLimiter');
const aiService = require('../services/aiService');
const promptService = require('../services/promptService');

const router = express.Router();

// POST /api/optimize
router.post('/optimize', verifyJWT, optimizeLimiter, async (req, res, next) => {
  try {
    const { rawPrompt, optimizationType = 'general' } = req.body;

    if (!rawPrompt || typeof rawPrompt !== 'string' || rawPrompt.trim() === '') {
      return res.status(400).json({
        error: { message: 'rawPrompt is required and must be a non-empty string.' },
      });
    }

    if (!aiService.VALID_TYPES.includes(optimizationType)) {
      return res.status(400).json({
        error: {
          message: `Invalid optimizationType. Must be one of: ${aiService.VALID_TYPES.join(', ')}.`,
        },
      });
    }

    const { allowed, usedToday, remaining } = await promptService.checkDailyLimit(req.user.userId);

    if (!allowed) {
      const now = new Date();
      const resetsAt = new Date(
        Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1)
      ).toISOString();

      return res.status(429).json({
        error: 'Daily optimization limit reached.',
        remainingRequests: 0,
        resetsAt,
      });
    }

    const { optimizedPrompt, tokensUsed } = await aiService.optimizePrompt(
      rawPrompt.trim(),
      optimizationType
    );

    const promptId = await promptService.savePrompt(
      req.user.userId,
      rawPrompt.trim(),
      optimizedPrompt,
      tokensUsed,
      optimizationType
    );

    return res.status(200).json({
      promptId,
      optimizedPrompt,
      tokensUsed,
      remainingRequests: remaining - 1,
      optimizationType,
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/usage
router.get('/usage', verifyJWT, async (req, res, next) => {
  try {
    const { usedToday, remainingToday, maxPerDay } = await promptService.getTodayUsage(
      req.user.userId
    );

    const now = new Date();
    const resetsAt = new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1)
    ).toISOString();

    return res.status(200).json({
      usedToday,
      remainingToday,
      maxPerDay,
      resetsAt,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
