const express = require('express');
const verifyJWT = require('../middleware/verifyJWT');
const promptService = require('../services/promptService');

const router = express.Router();

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// GET /api/history
router.get('/history', verifyJWT, async (req, res, next) => {
  try {
    let page = parseInt(req.query.page, 10) || 1;
    let limit = parseInt(req.query.limit, 10) || 10;

    if (page < 1) page = 1;
    if (limit < 1) limit = 1;
    if (limit > 50) limit = 50;

    const { prompts, totalCount } = await promptService.getUserPrompts(
      req.user.userId,
      page,
      limit
    );

    const totalPages = Math.ceil(totalCount / limit);

    return res.status(200).json({
      prompts,
      pagination: {
        totalCount,
        currentPage: page,
        totalPages,
        hasNextPage: page < totalPages,
        hasPrevPage: page > 1,
      },
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/history/:promptId
router.get('/history/:promptId', verifyJWT, async (req, res, next) => {
  try {
    const { promptId } = req.params;

    if (!UUID_REGEX.test(promptId)) {
      return res.status(400).json({ error: { message: 'Invalid promptId format. Must be a valid UUID.' } });
    }

    const prompt = await promptService.getPromptById(promptId, req.user.userId);

    if (!prompt) {
      return res.status(404).json({ error: { message: 'Prompt not found.' } });
    }

    return res.status(200).json({ prompt });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/history/:promptId
router.delete('/history/:promptId', verifyJWT, async (req, res, next) => {
  try {
    const { promptId } = req.params;

    if (!UUID_REGEX.test(promptId)) {
      return res.status(400).json({ error: { message: 'Invalid promptId format. Must be a valid UUID.' } });
    }

    const deleted = await promptService.deletePrompt(promptId, req.user.userId);

    if (!deleted) {
      return res.status(404).json({ error: { message: 'Prompt not found.' } });
    }

    return res.status(200).json({ message: 'Deleted successfully' });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
