const express = require('express');
const jwt = require('jsonwebtoken');
const googleAuth = require('../services/googleAuth');
const userModel = require('../models/user');
const config = require('../config/env');

const router = express.Router();

// POST /auth/google
router.post('/google', async (req, res, next) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: { message: 'idToken is required in request body.' } });
    }

    const { googleId, email, name, picture } = await googleAuth.verifyGoogleToken(idToken);

    const user = await userModel.upsertUser({
      googleId,
      email,
      displayName: name,
      picture,
    });

    const token = jwt.sign(
      { userId: user.id, email: user.email },
      config.jwt.secret,
      { expiresIn: config.jwt.expiresIn }
    );

    return res.status(200).json({
      token,
      user: {
        id: user.id,
        email: user.email,
        displayName: user.display_name,
        picture: user.picture,
      },
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
