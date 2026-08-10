# Sprint 01 – Foundation + User Registration

> **Status:** ✅ Complete
> **Dates:** Project start → 2026-08-10
> **Commit:** `feat(user): implement user registration endpoint with BCrypt hashing and global exception handling`

---

## Sprint Goal

Establish the project foundation and deliver the first real API feature: user registration.

---

## Milestones

### Milestone 1 – Project Initialization ✅

- Created the GitHub repository.
- Cloned into IntelliJ IDEA.
- Established the repository as the single source of truth.

**Why version control first?**
Every change is tracked, collaboration is safe, and rollbacks are possible. This mirrors professional team workflow.

---

### Milestone 2 – Spring Boot Backend Setup ✅

**Technology decisions:**

| Decision | Choice | Reason |
|---|---|---|
| Language | Java 21 | LTS, modern features (records, sealed classes) |
| Framework | Spring Boot 3.5.3 | Industry standard, production-ready, huge ecosystem |
| Build tool | Maven | Dependency management, build lifecycle |

**Initial dependencies:**

| Dependency | Purpose |
|---|---|
| `spring-boot-starter-web` | Build REST APIs |
| `spring-boot-starter-data-jpa` | ORM + database abstraction |
| `postgresql` | Database driver |
| `spring-boot-starter-validation` | Bean Validation (Jakarta) |
| `lombok` | Reduce boilerplate |
| `spring-boot-starter-test` | JUnit 5 + Mockito |
| `spring-boot-devtools` | Auto-restart on save |
| `spring-boot-starter-security` | BCryptPasswordEncoder |

---

### Milestone 3 – PostgreSQL Setup ✅

- Installed PostgreSQL 18 + pgAdmin.
- Created `back2kasi_db` database.
- Connected Spring Boot via `application.properties` + `application-local.properties`.

**Configuration strategy:**

| File | Contains | In version control? |
|---|---|---|
| `application.properties` | Shared settings, property keys | ✅ Yes |
| `application-local.properties` | DB password, local URLs | ❌ No (`.gitignore`) |

This mirrors how professional teams manage configuration across environments.

---

### Milestone 4 – Domain Modelling ✅

**Core question answered before writing any code:**

> *Who can use the platform?*

Decision: a single `User` entity for both customers and business owners. Business ownership is determined by whether a user owns any `Business` entities — not by a separate entity type or role flag.

**Benefits:**
- No duplicate data
- One login identity for all platform roles
- A person can both rent from others and own businesses

**User entity fields:**

| Field | Type | Constraints |
|---|---|---|
| `id` | `Long` | Auto-generated PK |
| `firstName` | `String` | Required |
| `lastName` | `String` | Required |
| `email` | `String` | Required, Unique |
| `password` | `String` | Required, BCrypt-hashed |
| `phoneNumber` | `String` | Required |
| `role` | `Enum` | `USER` / `ADMIN`, default = `USER` |
| `createdAt` | `LocalDateTime` | Auto-set on insert |
| `updatedAt` | `LocalDateTime` | Auto-set on update |

**Authentication:** Email + Password (no usernames).

---

### Milestone 5 – Architecture Decisions ✅

**Package structure:** Feature-based (not layer-based)

```
com.back2kasi/
├── auth/
├── user/
│   ├── controller/
│   ├── dto/
│   ├── entity/
│   ├── repository/
│   └── service/
├── business/
├── booking/
└── config/
```

All code for a specific business capability lives together. Cross-cutting concerns (security, exception handling) live in dedicated packages.

**Layered architecture:**

```
HTTP Request
    ↓
Controller   — HTTP concerns only
    ↓
Service      — Business logic only
    ↓
Repository   — Data access only
    ↓
PostgreSQL
```

No layer reaches past its immediate neighbour.

---

### Milestone 6 – User Registration Feature ✅

**The first complete end-to-end feature.**

```
POST /api/users/register
    → UserController         (HTTP)
    → UserService.register() (Business logic)
    → UserRepository.save()  (Data access)
    → PostgreSQL users table  (Persistence)
```

**Components built:**

#### `RegisterRequest` DTO

| Field | Validation |
|---|---|
| `firstName` | `@NotBlank` |
| `lastName` | `@NotBlank` |
| `email` | `@NotBlank`, `@Email` |
| `password` | `@NotBlank`, `@Size(min = 7)` |
| `phoneNumber` | `@NotBlank`, `@Pattern(+27XXXXXXXXX)` |

> The DTO separates the API contract from the entity. A change to the database schema does not break the API.

#### `UserService.register()` business rules

```
1. existsByEmail → 409 Conflict if duplicate
2. BCrypt hash the password
3. Build User entity (role = USER, always)
4. Save to database
```

> The role is **never** accepted from the client. The backend assigns it.

#### `UserController` — `POST /api/users/register`

- `@Valid` triggers Bean Validation at the boundary
- Returns `201 Created` on success
- Validation failures → `400 Bad Request` (field errors)
- Duplicate email → `409 Conflict`

#### `GlobalExceptionHandler`

| Exception | HTTP |
|---|---|
| `IllegalStateException` | `409 Conflict` |
| `MethodArgumentNotValidException` | `400 Bad Request` |

---

### Milestone 7 – Testing ✅

**8 tests written and passing:**

| Test class | Tests | Type |
|---|---|---|
| `UserServiceTest` | 2 | Unit (Mockito) |
| `UserControllerTest` | 6 | MVC slice (@WebMvcTest) |

**Service tests:**
- `register_savesUser_whenEmailIsNew` — happy path, BCrypt called, entity saved
- `register_throwsIllegalStateException_whenEmailAlreadyExists` — duplicate guard

**Controller tests:**
- `register_returns201_whenRequestIsValid`
- `register_returns400_whenFieldsAreMissing`
- `register_returns400_whenEmailIsInvalid`
- `register_returns400_whenPasswordIsTooShort`
- `register_returns400_whenPhoneNumberIsNotSouthAfrican`
- `register_returns409_whenEmailAlreadyExists`

---

## Registration Rules (Agreed)

| Field | Rule |
|---|---|
| First name | Required |
| Last name | Required |
| Email | Required, valid format, unique |
| Password | Required, minimum 7 characters |
| Phone number | Required, South African `+27XXXXXXXXX` format |
| Role | Not supplied by client — backend assigns `USER` |

**UX decision:** The frontend (Flutter) normalises the phone number before sending.
A user enters `082 123 4567`; Flutter converts it to `+27821234567` before the API call.
The backend always receives and stores the canonical `+27` format.

---

## Sprint Summary

| Component | Status |
|---|---|
| Project setup + GitHub | ✅ |
| PostgreSQL + DB connection | ✅ |
| Domain modelling | ✅ |
| User entity + Lombok | ✅ |
| UserRepository | ✅ |
| RegisterRequest DTO + validation | ✅ |
| BCryptPasswordEncoder | ✅ |
| UserService.register() | ✅ |
| UserController POST /api/users/register | ✅ |
| GlobalExceptionHandler | ✅ |
| Unit + slice tests (8 passing) | ✅ |
