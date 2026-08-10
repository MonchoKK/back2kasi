# Sprint 02 – Authentication (JWT Login)

> **Status:** ✅ Complete
> **Date:** 2026-08-10
> **Commit:** `feat(auth): implement JWT login + Spring Security filter chain`

---

## Sprint Goal

Implement login. A registered user submits their credentials and receives a JWT that Flutter will attach to every subsequent API request.

---

## Design Decisions

### What does the login request contain?

```json
{
  "email":    "kabelo@back2kasi.co.za",
  "password": "secret123"
}
```

Email and password only. Role is never accepted from the client.

---

### What does the login response contain?

```json
{
  "token":     "eyJhbGciOiJIUzI1NiJ9...",
  "tokenType": "Bearer",
  "expiresIn": 86400
}
```

| Field | Value | Purpose |
|---|---|---|
| `token` | Signed JWT string | The credential Flutter stores and sends |
| `tokenType` | `"Bearer"` | Tells the client how to use the token |
| `expiresIn` | `86400` (seconds) | 24 hours — Flutter knows when to re-authenticate |

Flutter attaches the token to every protected request:
```
Authorization: Bearer eyJhbGci...
```

---

### What happens when the email doesn't exist?

`401 Unauthorized` — `{ "error": "Invalid email or password" }`

---

### What happens when the password is wrong?

`401 Unauthorized` — `{ "error": "Invalid email or password" }`

> **Security decision:** Both bad-email and bad-password return **exactly the same message**.
> If the API revealed which field was wrong, an attacker could use the login endpoint to
> discover which email addresses are registered. This is called an **enumeration attack**.
> The generic message prevents it.

---

### How long is a JWT valid?

**24 hours (86 400 seconds).**

Mobile apps benefit from longer sessions — users don't want to re-login every time they open the app. A 24-hour window balances security with usability. Refresh tokens can be introduced in a future sprint.

---

### What information is inside the token (claims)?

| Claim | Value | Purpose |
|---|---|---|
| `sub` | email | Standard JWT subject — who the token belongs to |
| `userId` | DB id (Long) | Avoids a DB lookup on every request |
| `role` | `USER` / `ADMIN` | Role-based access control on protected routes |
| `iat` | issued-at timestamp | Standard — when the token was created |
| `exp` | expiry timestamp | Standard — when the token stops being valid |

---

### Signing algorithm

**HS256** (HMAC-SHA256) with a secret key.

The secret is read from an environment variable (`JWT_SECRET`). It never appears in source code.
The key must be at least 32 characters (256 bits) for HS256.

```
# application.properties
app.jwt.secret=${JWT_SECRET:back2kasi-local-dev-secret-please-change-in-production}
app.jwt.expiration-ms=86400000
```

---

## What Spring Security Does

Spring Security inserts a **filter chain** in front of every HTTP request. Before this sprint, the chain had one rule: `anyRequest().permitAll()`.

After this sprint:

```
HTTP Request
    ↓
[JwtAuthenticationFilter]   ← reads "Authorization: Bearer <token>",
    ↓                           validates it, sets the security context
[Security Rules]            ← /register and /login: public
    ↓                           everything else: requires a valid JWT
[Controller]
```

**Key configuration decisions:**

| Decision | Reason |
|---|---|
| **Stateless sessions** (`STATELESS`) | JWTs carry all auth state. The server never creates an HTTP session. |
| **CSRF disabled** | CSRF exploits browser cookies. JWTs live in the `Authorization` header — not in cookies — so CSRF is not a threat. |
| `/register` + `/login` public | Users need to be able to register and log in without a token. |
| Everything else `authenticated()` | All other routes require a valid, unexpired JWT. |

---

## How Password Verification Works

**During registration:**
```
Plain password → BCrypt → Hash stored in DB
```

**During login:**
```
Password entered
      ↓
BCrypt.matches(plain, storedHash)
      ↓
  true?     false?
   ↓           ↓
  JWT       BadCredentialsException → 401
```

BCrypt's `matches()` re-hashes the plain-text password with the salt extracted from the stored hash and compares. The plain password is **never stored or logged**.

---

## What a JWT Is

A JWT has three Base64url-encoded parts separated by dots:

```
eyJhbGciOiJIUzI1NiJ9   ← Header  (algorithm: HS256)
.
eyJzdWIiOiJrYWJlbG8i  ← Payload (claims: sub, userId, role, iat, exp)
.
SflKxwRJSMeKKF2QT4fw  ← Signature (HMAC of header + payload, signed with secret)
```

If anyone tampers with the payload, the signature check fails and the token is rejected. The server never needs to store sessions — the token is self-contained proof of identity.

---

## Components Built

### New files

| File | Purpose |
|---|---|
| `auth/dto/LoginRequest.java` | Inbound DTO: `email` + `password` |
| `auth/dto/AuthResponse.java` | Outbound DTO: `token`, `tokenType`, `expiresIn` |
| `auth/service/JwtService.java` | Generate, extract, validate JWTs |
| `auth/filter/JwtAuthenticationFilter.java` | `OncePerRequestFilter` — validates JWT on each request |

### Modified files

| File | Change |
|---|---|
| `User.java` | Implements `UserDetails` — Spring Security's auth interface |
| `UserService.java` | Implements `UserDetailsService` + new `login()` method |
| `UserController.java` | New `POST /api/users/login` endpoint |
| `SecurityConfig.java` | Full rewrite — stateless, JWT filter, route rules |
| `GlobalExceptionHandler.java` | `BadCredentialsException` → `401 Unauthorized` |
| `pom.xml` | Added `jjwt-api`, `jjwt-impl`, `jjwt-jackson` (0.12.6) |
| `application.properties` | Added `app.jwt.secret`, `app.jwt.expiration-ms` |

---

## JwtAuthenticationFilter — 5 steps

```
1. READ    "Authorization: Bearer <token>" header
           → No header or not Bearer? → pass through (Spring Security rejects if route is protected)

2. PARSE   Extract email from token's sub claim

3. LOAD    Call UserService.loadUserByUsername(email) → fetch user from DB

4. VALIDATE  jwtService.isTokenValid(token, userDetails)
             → Checks: subject matches + token not expired

5. SET     SecurityContextHolder.setAuthentication(...)
           → Downstream code now knows who is making the request
```

---

## UserDetails — Why the Entity Implements It

Spring Security has a standard interface: `UserDetails`. It answers:
- *Who are you?* (`getUsername()` → email)
- *What can you do?* (`getAuthorities()` → `[ROLE_USER]`)
- *Is your account active?* (4 boolean flags — all `true` for now)

Rather than creating a wrapper class, the `User` entity implements `UserDetails` directly. This is the standard approach: our domain object is the source of truth for auth details.

The `ROLE_USER` / `ROLE_ADMIN` convention (prefixed with `ROLE_`) is required by Spring Security's `hasRole()` checks.

---

## Login Flow (End to End)

```
Flutter:  POST /api/users/login  { email, password }
                ↓
  JwtAuthenticationFilter: no Authorization header → pass through
                ↓
  UserController.login(@Valid LoginRequest)
                ↓
  UserService.login(request):
    1. findByEmail(email)       → not found?  BadCredentialsException
    2. passwordEncoder.matches  → no match?   BadCredentialsException
    3. jwtService.generateToken(user)         → "eyJhbGci..."
    4. return AuthResponse(token, "Bearer", 86400)
                ↓
  200 OK  { token, tokenType, expiresIn }
                ↓
Flutter stores token, attaches to all future requests:
  Authorization: Bearer eyJhbGci...
```

---

## Tests

**19 total — 0 failures.**

| Test class | Count | New this sprint |
|---|---|---|
| `JwtServiceTest` | 5 | 5 ✨ |
| `UserControllerTest` | 9 | 3 ✨ |
| `UserServiceTest` | 5 | 3 ✨ |

### JwtServiceTest (unit — no Spring context)
- `generateToken_returnsWellFormedJwt` — token has 3 dot-separated segments
- `extractEmail_returnsEmailFromSubjectClaim`
- `isTokenValid_returnsTrue_forFreshTokenAndMatchingUser`
- `isTokenValid_returnsFalse_whenUserEmailDoesNotMatchSubject` — cross-user token rejected
- `getExpirationSeconds_convertsMsToSeconds` — 86 400 000 ms → 86 400 s

### UserControllerTest additions (MVC slice)
- `login_returns200WithToken_whenCredentialsAreValid`
- `login_returns401_whenEmailNotFound`
- `login_returns401_whenPasswordIsWrong`

### UserServiceTest additions (unit)
- `login_returnsAuthResponse_whenCredentialsAreValid`
- `login_throwsBadCredentialsException_whenEmailNotFound`
- `login_throwsBadCredentialsException_whenPasswordIsWrong`

---

## Test Infrastructure Note

`@WebMvcTest` + `@Import({SecurityConfig.class, JwtAuthenticationFilter.class})`

Because the new `SecurityConfig` depends on `JwtAuthenticationFilter`, the filter must be explicitly imported into the web-layer test context. A `@MockBean JwtService` is also required so the filter can be constructed — even though it short-circuits immediately on these public endpoints (no `Authorization` header is sent in the tests).

---

## Sprint Summary

| Component | Status |
|---|---|
| Login design decisions | ✅ |
| JJWT 0.12.6 dependency | ✅ |
| JWT config (secret + expiration) | ✅ |
| LoginRequest + AuthResponse DTOs | ✅ |
| JwtService (generate / validate) | ✅ |
| JwtAuthenticationFilter | ✅ |
| User implements UserDetails | ✅ |
| UserService implements UserDetailsService | ✅ |
| UserService.login() | ✅ |
| POST /api/users/login endpoint | ✅ |
| SecurityConfig — JWT filter chain | ✅ |
| BadCredentialsException → 401 | ✅ |
| 19 tests passing | ✅ |
| Committed and pushed to GitHub | ✅ |
