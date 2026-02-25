# Prompt Optimizer Backend

Node.js/Express REST API for the Prompt Optimizer app. Uses PostgreSQL for persistence, Google OAuth 2.0 for authentication, and OpenAI GPT-4o for prompt optimization.

---

## Prerequisites

- **Node.js** v18+
- **PostgreSQL** 14+
- A **Google Cloud** project with OAuth 2.0 credentials
- An **OpenAI API key**

---

## Setup

### 1. Clone and install

```bash
cd prompt-optimizer-backend
npm install
```

### 2. Configure environment

```bash
cp .env.example .env
```

Edit `.env` and fill in your values:

| Variable | Description |
|---|---|
| `PORT` | Port to listen on (default: 3000) |
| `DB_HOST` | PostgreSQL host (default: localhost) |
| `DB_PORT` | PostgreSQL port (default: 5432) |
| `DB_NAME` | Database name |
| `DB_USER` | Database user |
| `DB_PASSWORD` | Database password |
| `JWT_SECRET` | Secret for signing JWTs (use a long random string) |
| `JWT_EXPIRES_IN` | JWT expiry (e.g. `7d`) |
| `GOOGLE_CLIENT_ID` | From Google Cloud Console → OAuth 2.0 Credentials |
| `OPENAI_API_KEY` | From platform.openai.com |
| `ALLOWED_ORIGINS` | Comma-separated list of allowed CORS origins |
| `DAILY_OPTIMIZATION_LIMIT` | Max optimizations per user per day (default: 100) |

### 3. Get a Google Client ID

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project (or select existing)
3. Navigate to **APIs & Services → Credentials**
4. Click **Create Credentials → OAuth 2.0 Client ID**
5. Choose **Web application**, add your origin(s)
6. Copy the **Client ID** into `GOOGLE_CLIENT_ID`

### 4. Get an OpenAI API key

1. Go to [platform.openai.com](https://platform.openai.com/)
2. Navigate to **API Keys**
3. Create a new key and copy it into `OPENAI_API_KEY`

### 5. Set up the database

Ensure PostgreSQL is running and the `postgres` user exists:

```bash
# If the postgres role doesn't exist:
psql -U postgres -c "CREATE ROLE postgres WITH LOGIN SUPERUSER PASSWORD 'yourpassword';"

# Run the schema:
npm run db:setup
```

Expected output: tables and indexes created with no errors.

### 6. Start the server

```bash
npm run dev
```

Expected output:
```
[nodemon] starting `node server.js`
Database connected successfully
Server running on port 3000 (development)
```

---

## npm Scripts

| Script | Description |
|---|---|
| `npm start` | Start with `node` (production) |
| `npm run dev` | Start with `nodemon` (auto-restart on file changes) |
| `npm run db:setup` | Run `database/schema.sql` against PostgreSQL |
| `npm run db:reset` | Drop and recreate the database, then re-run schema |

---

## API Endpoints

### Health

```bash
curl http://localhost:3000/health
```

### Auth

#### POST /auth/google — Exchange Google ID token for JWT

```bash
curl -X POST http://localhost:3000/auth/google \
  -H "Content-Type: application/json" \
  -d '{"idToken": "YOUR_GOOGLE_ID_TOKEN"}'
```

Response:
```json
{
  "token": "eyJ...",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "displayName": "Jane Doe",
    "picture": "https://..."
  }
}
```

> Save the `token` value — pass it as `Authorization: Bearer <token>` on all protected endpoints.

---

### Optimize

#### POST /api/optimize — Optimize a prompt

```bash
curl -X POST http://localhost:3000/api/optimize \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"rawPrompt": "write me some code", "optimizationType": "coding"}'
```

Valid `optimizationType` values: `general`, `coding`, `creative`, `analysis`, `instruction`

Response:
```json
{
  "promptId": "uuid",
  "optimizedPrompt": "...",
  "tokensUsed": 312,
  "remainingRequests": 99,
  "optimizationType": "coding"
}
```

#### GET /api/usage — Check today's usage

```bash
curl http://localhost:3000/api/usage \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

Response:
```json
{
  "usedToday": 1,
  "remainingToday": 99,
  "maxPerDay": 100,
  "resetsAt": "2026-02-19T00:00:00.000Z"
}
```

---

### History

#### GET /api/history — List prompts (paginated)

```bash
curl "http://localhost:3000/api/history?page=1&limit=10" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

Response:
```json
{
  "prompts": [...],
  "pagination": {
    "totalCount": 5,
    "currentPage": 1,
    "totalPages": 1,
    "hasNextPage": false,
    "hasPrevPage": false
  }
}
```

#### GET /api/history/:promptId — Get a single prompt

```bash
curl http://localhost:3000/api/history/YOUR_PROMPT_UUID \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### DELETE /api/history/:promptId — Delete a prompt

```bash
curl -X DELETE http://localhost:3000/api/history/YOUR_PROMPT_UUID \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

Response:
```json
{ "message": "Deleted successfully" }
```

---

## Verify Data in PostgreSQL

```bash
psql -U postgres -d prompt_optimizer_dev
SELECT * FROM users;
SELECT * FROM prompts;
SELECT * FROM usage_logs;
```

---

## Migration to Production Checklist

- [ ] Set `NODE_ENV=production` in server environment
- [ ] Replace `JWT_SECRET` with a cryptographically random 64+ character string
- [ ] Set `ALLOWED_ORIGINS` to your production frontend URL only
- [ ] Use a managed PostgreSQL instance (e.g. AWS RDS, Google Cloud SQL)
- [ ] Set `DB_PASSWORD` via secrets manager — never hard-code in `.env` on server
- [ ] Increase `DB_HOST` pool `max` connections based on load
- [ ] Run `npm start` (not `npm run dev`) — or use PM2/systemd
- [ ] Put the API behind a reverse proxy (nginx/Caddy) with TLS
- [ ] Set up log aggregation (e.g. CloudWatch, Datadog)
- [ ] Add a process manager for restarts (PM2: `pm2 start server.js`)
- [ ] Review and tighten CORS to only necessary origins
- [ ] Set appropriate rate limits for production traffic levels
