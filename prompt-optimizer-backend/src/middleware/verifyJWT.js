const jwt = require('jsonwebtoken');
const config = require('../config/env');

const verifyJWT = (req, res, next) => {
  const authHeader = req.headers['authorization'];

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: { message: 'Missing or malformed Authorization header. Expected: Bearer <token>' },
    });
  }

  const token = authHeader.slice(7);

  try {
    const decoded = jwt.verify(token, config.jwt.secret);
    req.user = decoded;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: { message: 'Token has expired. Please sign in again.' } });
    }
    return res.status(401).json({ error: { message: 'Invalid token.' } });
  }
};

module.exports = verifyJWT;
