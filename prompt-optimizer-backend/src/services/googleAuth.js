const { OAuth2Client } = require('google-auth-library');
const config = require('../config/env');

const client = new OAuth2Client(config.google.clientId);

const verifyGoogleToken = async (idToken) => {
  const ticket = await client.verifyIdToken({
    idToken,
    audience: config.google.clientId,
  });

  const payload = ticket.getPayload();

  if (!payload) {
    throw new Error('Invalid Google ID token: empty payload');
  }

  return {
    googleId: payload.sub,
    email: payload.email,
    name: payload.name,
    picture: payload.picture,
  };
};

module.exports = { verifyGoogleToken };
