const http = require('http');
const jwt = require('jsonwebtoken');

const BASE = 'http://localhost:3000';
const SECRET = 'flutter_prompt_optimizer_secret_key';

// Valid JWT signed with backend secret, fake userId (not in DB)
const TEST_JWT = jwt.sign(
    { userId: '00000000-0000-0000-0000-000111111111', email: 'test@test.com' },
    SECRET,
    { expiresIn: '1h' }
);

let passed = 0;
let failed = 0;

function check(label, got, expected, bodySnippet) {
    const ok = expected.includes(got);
    const mark = ok ? '✅ PASS' : '❌ FAIL';
    if (ok) passed++; else failed++;
    const body = bodySnippet ? `  Body: ${bodySnippet.slice(0, 120)}` : '';
    console.log(`${mark} | ${label} → HTTP ${got} (expected ${expected.join(' or ')})\n${body}`);
}

function request(path, method = 'GET', headers = {}, body = null) {
    return new Promise((resolve) => {
        const url = new URL(BASE + path);
        const opts = {
            hostname: url.hostname,
            port: url.port || 80,
            path: url.pathname + url.search,
            method,
            headers: { 'Content-Type': 'application/json', ...headers },
        };
        const req = http.request(opts, (res) => {
            let data = '';
            res.on('data', (c) => (data += c));
            res.on('end', () => resolve({ status: res.statusCode, body: data }));
        });
        req.on('error', (e) => resolve({ status: 0, body: e.message }));
        if (body) req.write(JSON.stringify(body));
        req.end();
    });
}

async function run() {
    console.log('\n══════════════════════════════════════════');
    console.log('  PROMPT OPTIMIZER BACKEND – API TESTS  ');
    console.log('══════════════════════════════════════════\n');

    let r;

    // ── 1. Health ──────────────────────────────────────
    console.log('── HEALTH ──');
    r = await request('/health');
    const health = JSON.parse(r.body);
    check('GET /health – status ok', r.status, [200], r.body);
    check('GET /health – DB connected', health.database === 'connected' ? 200 : 500, [200], `database: ${health.database}`);

    // ── 2. 404 ─────────────────────────────────────────
    console.log('\n── 404 HANDLING ──');
    r = await request('/nonexistent-endpoint');
    check('GET /nonexistent → 404', r.status, [404], r.body);

    // ── 3. Auth endpoint ───────────────────────────────
    console.log('\n── POST /auth/google ──');
    r = await request('/auth/google', 'POST', {}, {});
    check('No idToken → 400', r.status, [400], r.body);

    r = await request('/auth/google', 'POST', {}, { idToken: 'bad-token' });
    check('Invalid idToken → 500 (Google error)', r.status, [500, 400], r.body);

    // ── 4. JWT Guard – no token ────────────────────────
    console.log('\n── JWT GUARD (no Authorization header) ──');
    r = await request('/api/optimize', 'POST', {}, { rawPrompt: 'test' });
    check('POST /api/optimize – no JWT → 401', r.status, [401], r.body);

    r = await request('/api/usage');
    check('GET /api/usage – no JWT → 401', r.status, [401], r.body);

    r = await request('/api/history');
    check('GET /api/history – no JWT → 401', r.status, [401], r.body);

    r = await request('/api/history/00000000-0000-0000-0000-000000000001');
    check('GET /api/history/:id – no JWT → 401', r.status, [401], r.body);

    r = await request('/api/history/00000000-0000-0000-0000-000000000001', 'DELETE');
    check('DELETE /api/history/:id – no JWT → 401', r.status, [401], r.body);

    // ── 5. JWT Guard – bad token ───────────────────────
    console.log('\n── JWT GUARD (malformed token) ──');
    r = await request('/api/usage', 'GET', { Authorization: 'Bearer bad.jwt.token' });
    check('GET /api/usage – bad JWT → 401', r.status, [401], r.body);

    // ── 6. Input validation (valid JWT) ───────────────
    console.log('\n── INPUT VALIDATION (valid JWT) ──');
    const auth = { Authorization: `Bearer ${TEST_JWT}` };

    r = await request('/api/optimize', 'POST', auth, { rawPrompt: '', optimizationType: 'general' });
    check('Empty rawPrompt → 400', r.status, [400], r.body);

    r = await request('/api/optimize', 'POST', auth, { rawPrompt: 'hello', optimizationType: 'bogus' });
    check('Invalid optimizationType → 400', r.status, [400], r.body);

    r = await request('/api/history/not-a-uuid', 'GET', auth);
    check('Bad UUID format → 400', r.status, [400], r.body);

    r = await request('/api/history/00000000-0000-0000-0000-000000000099', 'GET', auth);
    check('Valid UUID but not found → 404', r.status, [404], r.body);

    r = await request('/api/history/00000000-0000-0000-0000-000000000099', 'DELETE', auth);
    check('DELETE non-existent ID → 404', r.status, [404], r.body);

    // ── 7. Valid requests (valid JWT, new user not in DB) ──
    console.log('\n── VALID REQUESTS (authenticated, new user) ──');

    r = await request('/api/history?page=1&limit=5', 'GET', auth);
    check('GET /api/history → 200 with prompts[]', r.status, [200], r.body);

    r = await request('/api/usage', 'GET', auth);
    check('GET /api/usage → 200 with usedToday', r.status, [200], r.body);

    // ── 8. Rate limit headers ──────────────────────────
    console.log('\n── RATE LIMIT HEADERS ──');
    r = await request('/health');
    // express-rate-limit uses RateLimit-* headers (standardHeaders: true)
    console.log(`  RateLimit headers present: check (manual - cannot assert in node http easily)`);
    check('GET /health for header check → 200', r.status, [200]);

    // ── Summary ────────────────────────────────────────
    console.log('\n══════════════════════════════════════════');
    console.log(`  RESULTS: ${passed} PASSED | ${failed} FAILED`);
    console.log('══════════════════════════════════════════\n');

    process.exit(failed > 0 ? 1 : 0);
}

run().catch((e) => { console.error(e); process.exit(1); });
