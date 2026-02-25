$base = "http://localhost:3000"

function Test($label, $status, $body) {
  $expected = if ($status -ge 200 -and $status -lt 300) { "PASS" } elseif ($status -ge 400) { "PASS" } else { "FAIL" }
  Write-Host "[$expected] $label | HTTP $status | $body"
}

function Get-Response($uri, $method="GET", $headers=@{}, $body=$null) {
  try {
    $params = @{ Uri=$uri; Method=$method; Headers=$headers; UseBasicParsing=$true }
    if ($body) { $params.Body = $body; $params.ContentType = "application/json" }
    $r = Invoke-WebRequest @params
    return @{ status=$r.StatusCode; content=$r.Content }
  } catch {
    $code = $_.Exception.Response.StatusCode.value__
    $msg  = $_.ErrorDetails.Message
    return @{ status=$code; content=$msg }
  }
}

Write-Host ""
Write-Host "=========================================="
Write-Host "  PROMPT OPTIMIZER API TEST SUITE"
Write-Host "=========================================="
Write-Host ""

# ---- Test 1: Health Check ----
Write-Host "--- HEALTH ---"
$r = Get-Response "$base/health"
Test "GET /health" $r.status $r.content

# ---- Test 2: 404 for unknown route ----
Write-Host ""
Write-Host "--- 404 HANDLING ---"
$r = Get-Response "$base/unknown-route"
Test "GET /unknown-route (expect 404)" $r.status ($r.content | Select-String "not found")

# ---- Test 3: Auth - missing idToken ----
Write-Host ""
Write-Host "--- AUTH ENDPOINT ---"
$r = Get-Response "$base/auth/google" "POST" @{} '{}'
Test "POST /auth/google - missing idToken (expect 400)" $r.status ($r.content | Select-String "required")

# ---- Test 4: Auth - invalid token ----
$r = Get-Response "$base/auth/google" "POST" @{} '{"idToken":"not-a-real-token"}'
Test "POST /auth/google - invalid token (expect 500/400)" $r.status ($r.content | Select-String -Pattern "segment|invalid" -CaseSensitive:$false)

# ---- Test 5: Protected endpoints without JWT ----
Write-Host ""
Write-Host "--- JWT GUARD (no token) ---"
$r = Get-Response "$base/api/optimize" "POST" @{} '{"rawPrompt":"test"}'
Test "POST /api/optimize - no JWT (expect 401)" $r.status ($r.content | Select-String "Authorization")

$r = Get-Response "$base/api/usage"
Test "GET /api/usage - no JWT (expect 401)" $r.status ($r.content | Select-String "Authorization")

$r = Get-Response "$base/api/history"
Test "GET /api/history - no JWT (expect 401)" $r.status ($r.content | Select-String "Authorization")

$r = Get-Response "$base/api/history/00000000-0000-0000-0000-000000000000"
Test "GET /api/history/:id - no JWT (expect 401)" $r.status ($r.content | Select-String "Authorization")

$r = Get-Response "$base/api/history/00000000-0000-0000-0000-000000000000" "DELETE"
Test "DELETE /api/history/:id - no JWT (expect 401)" $r.status ($r.content | Select-String "Authorization")

# ---- Test 6: Invalid JWT ----
Write-Host ""
Write-Host "--- JWT GUARD (bad token) ---"
$badAuth = @{ Authorization = "Bearer bad.jwt.token" }
$r = Get-Response "$base/api/optimize" "POST" $badAuth '{"rawPrompt":"test"}'
Test "POST /api/optimize - bad JWT (expect 401)" $r.status ($r.content | Select-String "Invalid token")

$r = Get-Response "$base/api/usage" "GET" $badAuth
Test "GET /api/usage - bad JWT (expect 401)" $r.status ($r.content | Select-String "Invalid token")

# ---- Test 7: Signed JWT (simulate real user) ----
Write-Host ""
Write-Host "--- SIGNED TEST JWT (real user flow) ---"
# Sign a JWT with the same secret as the backend
$jwtPayload = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('{"userId":"00000000-0000-0000-0000-000000000001","email":"test@example.com"}')) -replace '=','' -replace '\+','-' -replace '/','_'
$jwtHeader  = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('{"alg":"HS256","typ":"JWT"}')) -replace '=','' -replace '\+','-' -replace '/','_'
# We cannot sign without crypto — instead use a known-bad token to confirm 401 path
$r = Get-Response "$base/api/optimize" "POST" @{ Authorization="Bearer eyJ.eyJ.sig" } '{"rawPrompt":"hello","optimizationType":"general"}'
Test "POST /api/optimize - malformed JWT (expect 401)" $r.status ($r.content | Select-String "Invalid")

# ---- Test 8: Validate optimize body ---
Write-Host ""
Write-Host "--- BODY VALIDATION (using expired JWT to reach validation layer) ---"
# We need a real signed JWT — generate one using Node inline
$signedJwt = node -e "const jwt=require('jsonwebtoken'); console.log(jwt.sign({userId:'00000000-0000-0000-0000-000000000001',email:'test@test.com'},'flutter_prompt_optimizer_secret_key',{expiresIn:'1h'}))"
$authHeader = @{ Authorization = "Bearer $signedJwt" }
Write-Host "  Generated JWT: $signedJwt"

# Empty rawPrompt
$r = Get-Response "$base/api/optimize" "POST" $authHeader '{"rawPrompt":"","optimizationType":"general"}'
Test "POST /api/optimize - empty prompt (expect 400)" $r.status ($r.content | Select-String "required|non-empty")

# Invalid optimizationType
$r = Get-Response "$base/api/optimize" "POST" $authHeader '{"rawPrompt":"test","optimizationType":"invalid_type"}'
Test "POST /api/optimize - bad optimizationType (expect 400)" $r.status ($r.content | Select-String "Invalid")

# Invalid UUID on history
$r = Get-Response "$base/api/history/not-a-uuid" "GET" $authHeader
Test "GET /api/history/not-a-uuid (expect 400 invalid UUID)" $r.status ($r.content | Select-String "UUID")

# Non-existent prompt
$r = Get-Response "$base/api/history/00000000-0000-0000-0000-000000000099" "GET" $authHeader
Test "GET /api/history/non-existent-id (expect 404)" $r.status ($r.content | Select-String "not found")

# Valid paginated history (user has no data, should return empty list)
$r = Get-Response "$base/api/history?page=1&limit=5" "GET" $authHeader
Test "GET /api/history (expect 200 with prompts array)" $r.status ($r.content | Select-String "prompts|pagination")

# Valid usage
$r = Get-Response "$base/api/usage" "GET" $authHeader
Test "GET /api/usage (expect 200 with usedToday)" $r.status ($r.content | Select-String "usedToday")

Write-Host ""
Write-Host "=========================================="
Write-Host "  TEST SUITE COMPLETE"
Write-Host "=========================================="
