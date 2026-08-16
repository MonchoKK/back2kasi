# Back2Kasi Engineering Log

> **Last Updated:** 2026-08-11 | **Current Sprint:** Sprint 4 – Rental Unit Management

---

## Sprint Index

| Sprint | Focus | Status | Log |
|--------|-------|--------|-----|
| Sprint 1 – Foundation | Project Init, Backend Setup, Domain Modelling, User Registration | ✅ Complete | [Sprint-01-Foundation.md](Engineering-Logs/Sprint-01-Foundation.md) |
| Sprint 2 – Authentication | JWT Login, Spring Security Filter Chain | ✅ Complete | [Sprint-02-Authentication.md](Engineering-Logs/Sprint-02-Authentication.md) |
| Sprint 3 – Business Management | Business entity, ownership model, CRUD API, ownership enforcement | ✅ Complete | — |
| Sprint 4 – Rental Unit Management | RentalUnit entity, belongs-to-business, availability, CRUD API | 🔲 In Progress | — |

---

## Sprint 1 – Foundation

### Project Goal

Build a scalable digital platform for toilet rental and cold room rental businesses in South Africa.

The platform will replace WhatsApp, phone calls, and manual record-keeping with a modern booking and business management system.

---

### Milestone 1 – Project Initialization ✅

**Objectives**
- Create the GitHub repository.
- Clone the project locally.
- Set up the development environment.

**Completed**
- Created the GitHub repository.
- Cloned the repository into IntelliJ IDEA.
- Established the repository as the single source of truth for the project.

**Why this matters**

Version control allows us to:
- Track every change.
- Collaborate safely.
- Roll back to previous versions if needed.
- Maintain a professional development workflow.

---

### Milestone 2 – Backend Setup ✅

**Objectives**

Create the Spring Boot backend.

**Technology Decisions**

| Decision | Choice | Reason |
|----------|--------|--------|
| Language | Java 21 | LTS, modern features |
| Framework | Spring Boot 3.x | Industry standard, production-ready |
| Build Tool | Maven | Dependency management, build lifecycle |

**Dependencies Added**
- Spring Web
- Spring Data JPA
- PostgreSQL Driver
- Bean Validation
- Lombok
- Spring Boot Test

**Why this matters**

This gives us a production-ready backend foundation capable of exposing REST APIs, connecting to a relational database, validating user input, and supporting automated testing.

---

### Milestone 3 – PostgreSQL Installation ✅

**Objectives**

Install a relational database for persistent storage.

**Completed**
- Installed PostgreSQL 18.
- Installed pgAdmin.
- Connected to the PostgreSQL server.
- Created the `back2kasi_db` database.

**Why PostgreSQL?**

Back2Kasi contains highly related data:
- Users
- Businesses
- Rental Units
- Bookings

A relational database is the right choice because these entities have well-defined relationships and require transactional consistency.

---

### Milestone 4 – Spring Boot Database Connection ✅

**Objectives**

Connect the backend application to PostgreSQL.

**Completed**
- Configured datasource properties.
- Used `application.properties` for shared configuration.
- Used `application-local.properties` for machine-specific settings.
- Successfully connected Spring Boot to PostgreSQL.

**Important Decision**

Sensitive information such as database passwords will remain outside version control using local configuration files.

**Why this matters**

This mirrors how professional teams manage configuration across development, testing, and production environments.

---

### Milestone 5 – Domain Modelling: User Design ✅

Before writing any code, we designed the business model.

**Questions Answered**

*Who can use the platform?*
- Customers
- Business Owners

**Final Decision**

There will be a single `User` entity.

Business ownership will be determined by the businesses a user owns, rather than by separate customer and business-owner entities.

**Benefits**
- Eliminates duplicate data.
- Simplifies authentication.
- Allows one person to both rent from others and own businesses.
- Scales naturally as the platform grows.

#### User Entity Design Decisions

| Field | Type | Constraints | Reason |
|-------|------|-------------|--------|
| `id` | `Long` | Auto-generated (PK) | Simple for MVP, easy to debug |
| `email` | `String` | Required, Unique | Primary login identity |
| `password` | `String` | Required, Hashed | Never stored in plain text |
| `phoneNumber` | `String` | Required, Non-unique | Multiple users may share a number |
| `role` | `Enum` | `USER`, `ADMIN` | Basic access control |

**Authentication:** Email + Password (no usernames required)

**Roles:**
- `USER` – standard platform user
- `ADMIN` – administrative access

> Business ownership is represented through the `User` → `Business` relationship, not a special role.

---

### Milestone 6 – First JPA Entity ✅

Created the first domain entity: `User`

**JPA Concepts Learned**

| Annotation | Purpose |
|------------|---------|
| `@Entity` | Marks class as a JPA-managed entity |
| `@Table` | Maps entity to a specific DB table |
| `@Id` | Designates the primary key field |
| `@GeneratedValue` | Auto-generates PK values |
| `@Column` | Configures column constraints |
| `@Enumerated(EnumType.STRING)` | Stores enum as readable string |

**Result**

Hibernate automatically generated the `users` table inside PostgreSQL without writing SQL manually — demonstrating the power of JPA ORM.

---

### Milestone 7 – Understanding Repositories ✅

Explored the Repository pattern before implementing it.

**Learned**

Repositories are responsible only for data access. They provide methods such as:
- Save
- Find
- Update
- Delete

Spring Data JPA generates implementations automatically when extending `JpaRepository`.

Method names like `findByEmail` and `existsByEmail` are converted into SQL queries automatically by Spring.

---

### Architecture Decisions

**Package Structure:** Feature-based

```
user/
    controller/
    dto/
    entity/
    repository/
    service/

business/
booking/
rentalunit/
```

This keeps all code related to a specific business capability together and improves maintainability.

---

### Engineering Principles

> Agreed upon at the start of the project and applied throughout.

1. Understand the business before writing code.
2. Design before implementation.
3. Build features incrementally.
4. Keep commits small and meaningful.
5. Test every feature before marking it complete.
6. Use clean, maintainable code.
7. Keep responsibilities separated across layers.
8. Prefer simplicity for the MVP while designing for future growth.

---

### Sprint 1 Status

#### ✅ Completed
- Project initialization
- Spring Boot setup
- PostgreSQL setup
- Database connection
- User domain design
- User entity (`User.java`)
- Understanding the Repository pattern

**Sprint 1 is complete. All objectives met.**

---

## Sprint 2 – Core User Layer

> **Sprint Goal:** Wire together the full data access and business logic layers. Build the first real service, and set up the complete stack for user registration.

---

### Milestone 8 – UserRepository Implementation ✅

**Objectives**
- Implement `UserRepository` as a Spring Data JPA interface.
- Define custom query methods needed for user management.

**What was built**

`UserRepository` extends `JpaRepository<User, Long>` and adds two domain-specific methods:

```java
Optional<User> findByEmail(String email);
boolean existsByEmail(String email);
```

**Concepts Applied**

| Concept | Detail |
|---------|--------|
| `JpaRepository<T, ID>` | Provides full CRUD + pagination for free |
| Derived query methods | Spring translates method names into SQL at startup |
| `Optional<User>` | Forces the caller to handle the "not found" case explicitly |
| `boolean existsByEmail` | Efficient existence check — avoids loading the full entity |

**Why `Optional<User>` instead of `User`?**

Returning `Optional` forces every caller to explicitly handle the case where no user is found. This eliminates a whole class of `NullPointerException` bugs before they can happen.

**Why `existsByEmail` instead of just using `findByEmail`?**

During registration, we only need to know *whether* an account exists — not fetch the full user object. `existsByEmail` translates to `SELECT EXISTS(...)` which is far cheaper than loading an entire row.

---

### Milestone 9 – Understanding Dependency Injection ✅

Before writing the `UserService`, we studied how Spring's IoC container works.

**Core Concept**

Dependency Injection means: *your class declares what it needs, and Spring provides it.* You never call `new UserRepository()` — Spring creates it, manages its lifecycle, and injects it wherever it's needed.

**How Spring resolves dependencies**

```
1. Spring scans for @Component, @Service, @Repository, @Controller
2. Registers each as a "bean" in the Application Context
3. When a class declares a dependency, Spring injects the managed instance
```

**Three injection styles**

| Style | Mechanism | Verdict |
|-------|-----------|--------|
| Constructor injection | `final` field + constructor param | ✅ Preferred — dependencies are explicit and immutable |
| Field injection | `@Autowired` on a field | ❌ Hides dependencies, makes testing harder |
| Setter injection | `@Autowired` on a setter | Use only for optional dependencies |

**Decision:** Constructor injection will be used throughout this project via Lombok's `@RequiredArgsConstructor`.

**Key annotations learned**

| Annotation | What it does |
|------------|--------------|
| `@Service` | Marks a class as a Spring-managed service bean |
| `@Repository` | Marks a class as a data-access bean |
| `@Autowired` | Marks a dependency for injection (rarely used explicitly with constructor injection) |
| `@RequiredArgsConstructor` | Lombok generates a constructor for all `final` fields — pairs perfectly with constructor DI |

**Why this matters**

Dependency Injection is what makes the architecture work. Services don't create their own repositories. Controllers don't create their own services. Each layer depends on an abstraction — and Spring glues everything together at runtime. This is what makes the code testable, modular, and maintainable.

---

### Milestone 10 – UserService (Initial Skeleton) ✅

**Objectives**
- Create `UserService` to demonstrate how Spring injects `UserRepository`.
- Keep it small intentionally — no business logic yet.
- Establish the service layer pattern for the whole project.

**What was built**

```java
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;

    // Business logic will live here.
    // First use case: user registration.
}
```

**Concepts Demonstrated**

| Element | Role |
|---------|------|
| `@Service` | Registers the class as a Spring bean in the service layer |
| `private final UserRepository` | Declares the dependency — Spring will inject it |
| `@RequiredArgsConstructor` | Lombok generates the constructor; Spring uses it to inject `userRepository` |

**The layer contract**

```
Controller  →  UserService  →  UserRepository  →  PostgreSQL
    ↑               ↑                ↑
  HTTP layer   Business logic    Data access
```

No layer reaches past its immediate neighbour. The controller knows nothing about the database. The repository knows nothing about HTTP.

**Why start small?**

Creating the skeleton first — before any business logic — validates that Spring's wiring is correct. If `UserService` starts up and `UserRepository` is successfully injected, the application context is healthy. We can then add behaviour with confidence.

---

### Milestone 11 – User Registration Feature ✅

**The first complete end-to-end feature.** All four layers working together for the first time.

```
POST /api/users/register
    → UserController        (HTTP layer)
    → UserService.register() (Business logic)
    → UserRepository.save()  (Data access)
    → PostgreSQL users table  (Persistence)
```

#### What was built

**`RegisterRequest` DTO**

A dedicated Data Transfer Object separating the API contract from the database schema.

| Field | Validation |
|-------|------------|
| `firstName` | `@NotBlank` |
| `lastName` | `@NotBlank` |
| `email` | `@NotBlank`, `@Email` |
| `password` | `@NotBlank`, `@Size(min = 8)` |
| `phoneNumber` | `@NotBlank` |

**Why a DTO instead of the `User` entity directly?**
Exposing the entity couples the database schema to the API contract. A change to one breaks the other. The DTO is the public API shape; the entity is the private persistence shape.

---

**`SecurityConfig`**

Added Spring Security (`spring-boot-starter-security`) for `BCryptPasswordEncoder`.

Two beans declared:
- `SecurityFilterChain` — permits all requests during MVP (JWT comes later)
- `PasswordEncoder` — `BCryptPasswordEncoder` injectable anywhere in the app

**Why BCrypt?**
BCrypt is the industry standard. It is adaptive (work factor increases over time), automatically salts each hash, and makes brute-force and rainbow-table attacks impractical.

---

**`UserService.register()` — Business Logic**

```
1. Check existsByEmail → throw IllegalStateException if duplicate
2. Hash password with BCryptPasswordEncoder
3. Build User entity from RegisterRequest DTO
4. Save via UserRepository
```

---

**`UserController`**

```
POST /api/users/register
→ @RequestBody @Valid RegisterRequest
→ userService.register(request)
→ 201 Created: "User registered successfully"
```

`@Valid` triggers Bean Validation at the controller boundary before business logic runs.

---

### Milestone 12 – Global Exception Handler ✅

Added `GlobalExceptionHandler` with `@RestControllerAdvice` to return proper HTTP responses instead of raw `500` errors.

| Exception | HTTP Response |
|-----------|---------------|
| `IllegalStateException` | `409 Conflict` + `{"error": "message"}` |
| `MethodArgumentNotValidException` | `400 Bad Request` + field-level validation errors |

**Why this matters:**
Without an exception handler, Spring returns a generic `500` with a long stack trace. A proper handler maps business exceptions to meaningful HTTP status codes — making the API predictable and safe for clients.

---

### Milestone 13 – End-to-End Verification ✅

All three test cases verified:

| Test | Request | Expected | Result |
|------|---------|----------|--------|
| Happy path | Valid new user | `201 Created` | ✅ `"User registered successfully"` |
| Duplicate email | Same email twice | `409 Conflict` | ✅ `{"error": "An account with this email address already exists: ..."}` |
| Invalid input | Bean Validation | `400 Bad Request` | ✅ Field-level errors returned |

User rows confirmed in **pgAdmin** with BCrypt-hashed passwords (`$2a$10$...`) — never plain text.

**Commit:** `feat(user): implement user registration endpoint with BCrypt hashing and global exception handling`

---

### Sprint 2 Status

#### ✅ Completed
- `UserRepository` implementation
- Dependency Injection concepts learned
- `RegisterRequest` DTO with Bean Validation
- Spring Security + `BCryptPasswordEncoder`
- `SecurityConfig` (JWT filter chain, route rules)
- `UserService.register()` + `UserService.login()` business logic
- `UserController` — `POST /api/users/register` + `POST /api/users/login`
- `GlobalExceptionHandler` — `409`, `400`, `401` responses
- JWT authentication (login returns a signed token)
- `JwtService`, `JwtAuthenticationFilter`, `UserDetails` wiring
- 19 tests passing (unit + MVC slice)
- Pushed to GitHub

**Sprint 2 is complete.**

> Detailed design decisions and implementation notes are recorded in
> [Engineering-Logs/Sprint-02-Authentication.md](Engineering-Logs/Sprint-02-Authentication.md)

---

## Sprint 3 – Business Management

> **Sprint Goal:** Build the complete `Business` feature slice — entity, repository, service, REST API, and tests. Establish the ownership model that will underpin every future feature.

---

### Milestone 14 – Business Domain Design ✅

**Questions Answered**

*Can a user own multiple businesses?*
Yes. A user who owns businesses is a business owner. A user who owns none is a customer. Both are the same entity — ownership is represented by the relationship, not a role.

*Should `businessType` live on the `Business` entity or the `RentalUnit`?*
Both. The business declares what category it operates in. Individual rental units may vary in type (e.g. a business could rent both standard and VIP toilets).

**Design Decisions**

| Decision | Choice | Reason |
|----------|--------|--------|
| Business ID type | `Long` | Consistent with existing `User` entity for MVP |
| Soft delete | No — hard delete | Simpler for MVP; Flyway migration can add soft delete later |
| `businessType` on `Business` | Yes (`TOILET_RENTAL`, `COLD_ROOM_RENTAL`) | Cheaper to add now than migrate later |
| Updatable fields | All non-system fields | Name, description, address, phone, type |

**Relationship Model**

```
User (1) ──────────< Business (Many)
```

- A `User` who owns one or more `Business` entities is a business owner.
- Deleting a `User` cascades to delete all their `Business` rows (`CascadeType.ALL`, `orphanRemoval = true`).
- The `owner_id` FK column lives on the `businesses` table.

---

### Milestone 15 – Business Entity ✅

Created `Business.java` and `BusinessType.java`.

| Field | Type | Notes |
|-------|------|-------|
| `id` | `Long` | Auto-generated PK |
| `name` | `String` | Required — display name |
| `description` | `String` | Optional tagline |
| `address` | `String` | Required — physical address |
| `phoneNumber` | `String` | Required — business contact |
| `businessType` | `BusinessType` | Enum stored as `STRING` |
| `owner` | `User` | `@ManyToOne LAZY` — FK `owner_id` |
| `createdAt` | `LocalDateTime` | `@CreationTimestamp` |
| `updatedAt` | `LocalDateTime` | `@UpdateTimestamp` |

**Why `FetchType.LAZY` on `owner`?**

Lazy loading means the `User` is not fetched from the database unless explicitly accessed. Without this, every query for a business would issue a JOIN to fetch the full owner record — unnecessary overhead when we only need `owner_id`.

**`User.java` updated** — added the inverse `@OneToMany(mappedBy = "owner", cascade = ALL, orphanRemoval = true)` so Hibernate understands both sides of the relationship.

---

### Milestone 16 – BusinessRepository ✅

`BusinessRepository` extends `JpaRepository<Business, Long>` and adds:

```java
List<Business> findByOwnerId(Long ownerId);
boolean existsByIdAndOwnerId(Long id, Long ownerId);
```

**Why `findByOwnerId` instead of `findByOwner(User)`?**

Passing the full `User` entity just to query by ID is wasteful — it requires loading the `User` first. `findByOwnerId(Long)` translates directly to `WHERE owner_id = ?`, which is more efficient and avoids an extra query.

**Why `existsByIdAndOwnerId`?**

Used in the service's ownership check. Translates to `SELECT EXISTS(SELECT 1 FROM businesses WHERE id = ? AND owner_id = ?)` — a single, cheap query that verifies both existence and ownership simultaneously.

---

### Milestone 17 – Business Service ✅

Introduced the `Service` / `ServiceImpl` naming standard for the first time.

**`BusinessService` (interface)** — the public contract, independently testable.

**`BusinessServiceImpl`** — enforces all business rules:

| Operation | Rule enforced |
|-----------|---------------|
| Create | Owner must exist; entity built from DTO |
| Get all | Scoped to `ownerId` — never returns other users' businesses |
| Get by ID | Two-step: fetch → verify ownership (precise error: 404 vs 403) |
| Update | Verify ownership, apply all fields, let Hibernate dirty-check flush |
| Delete | Verify ownership, hard delete |

**Two-step ownership check**

```
1. businessRepository.findById(id)      → 404 if missing
2. business.getOwner().getId() == caller → 403 if different owner
```

A single `existsByIdAndOwnerId` would collapse both failure cases into the same result, making it impossible to distinguish "business doesn't exist" from "business exists but belongs to someone else". Two steps gives precise, actionable error responses.

**Why `@Transactional(readOnly = true)` on reads?**

Read-only transactions allow the database to optimise (e.g. skip dirty-checking, use read replicas). Mutation operations use `@Transactional` to guarantee atomicity — a crash mid-update rolls back automatically.

**New custom exceptions created:**

| Exception | HTTP |
|-----------|------|
| `ResourceNotFoundException` | `404 Not Found` |
| `UnauthorizedException` | `403 Forbidden` |

`GlobalExceptionHandler` updated to handle both.

---

### Milestone 18 – Business API ✅

```
POST   /api/v1/businesses          → 201 Created
GET    /api/v1/businesses          → 200 OK
GET    /api/v1/businesses/{id}     → 200 OK / 404 / 403
PUT    /api/v1/businesses/{id}     → 200 OK / 404 / 403
DELETE /api/v1/businesses/{id}     → 204 No Content / 404 / 403
```

**`@AuthenticationPrincipal`**

Instead of parsing the JWT manually in the controller, `@AuthenticationPrincipal User currentUser` extracts the authenticated `User` directly from Spring Security's `SecurityContext`. The `JwtAuthenticationFilter` already placed it there on every valid request — the controller simply uses it.

All routes are JWT-protected via the existing `anyRequest().authenticated()` rule in `SecurityConfig`. No extra annotation is needed.

---

### Milestone 19 – Tests ✅

**`spring-security-test` added** to `pom.xml` (test scope).

**`BusinessServiceImplTest`** — 12 pure unit tests (Mockito, no Spring context):
- Create: happy path + owner not found
- Get all: list + empty list
- Get by ID: happy path + 404 + 403
- Update: happy path + 403
- Delete: happy path + 403 + 404

**`BusinessControllerTest`** — 11 `@WebMvcTest` slice tests:

Authentication in `@WebMvcTest` with a real `SecurityConfig`:
- `SecurityMockMvcRequestPostProcessors.user(authenticatedUser)` is used on every request.
- This injects the real `User` entity into the `SecurityContext` for that request, satisfying `anyRequest().authenticated()` and resolving `@AuthenticationPrincipal` correctly — without sending a real JWT.

---

### Sprint 3 Status

#### ✅ Completed
- `BusinessType` enum
- `Business` JPA entity + `User` inverse relationship
- `BusinessRepository` with ownership-scoped queries
- `CreateBusinessRequest`, `UpdateBusinessRequest`, `BusinessResponse` DTOs
- `ResourceNotFoundException` + `UnauthorizedException`
- `GlobalExceptionHandler` updated (404 + 403)
- `BusinessService` interface + `BusinessServiceImpl`
- `BusinessController` — 5 REST endpoints
- `spring-security-test` added to `pom.xml`
- 23 new tests (12 unit + 11 MVC) — all 42 tests passing
- Pushed to GitHub: `feat(business): implement Business entity, repository, service, and API with ownership enforcement`

**Sprint 3 is complete.**

#### 🔲 Next (Sprint 4 – Rental Unit Management)
- Design the `RentalUnit` entity — belongs to a `Business`, owned indirectly by a `User`
- Answer product questions: what makes a rental unit unique? availability model? pricing?
- Implement CRUD for rental units (owner-only operations)
- Public listing endpoint (no JWT required — customers browse without logging in)

---

## Project Vision

> The goal is not simply to build an application.
>
> The goal is to build a **real software product** using professional software engineering practices — creating a codebase that is understandable, maintainable, testable, and ready for deployment.
