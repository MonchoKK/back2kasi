# Back2Kasi — Development Standards

> This document defines the coding conventions, package structure, Git workflow,
> naming rules, and API standards for the Back2Kasi platform.
> **Every contributor must follow these standards from day one.**

---

## Table of Contents

1. [Project Structure](#1-project-structure)
2. [Package Conventions](#2-package-conventions)
3. [Naming Rules](#3-naming-rules)
4. [Java Coding Standards](#4-java-coding-standards)
5. [REST API Standards](#5-rest-api-standards)
6. [Database Conventions](#6-database-conventions)
7. [Git Workflow](#7-git-workflow)
8. [Testing Standards](#8-testing-standards)
9. [Error Handling](#9-error-handling)
10. [Logging](#10-logging)

---

## 1. Project Structure

```
back2kasi/
├── backend/          ← Spring Boot REST API  (this document applies here)
├── app/              ← Mobile / frontend application
└── docs/             ← Project-level documentation
```

---

## 2. Package Conventions

Packages are organised around **business capabilities**, not technical layers.

```
com.back2kasi
│
├── Back2KasiApplication.java   ← single entry-point
│
├── config/          ← Cross-cutting config (Security, CORS, OpenAPI, …)
├── common/          ← Shared utilities used by all feature modules
│   ├── exception/   ← Custom exceptions + GlobalExceptionHandler
│   ├── response/    ← ApiResponse<T> wrapper
│   └── util/        ← Pure utility/helper classes
│
├── auth/            ← Authentication & authorisation
├── business/        ← Business (owner/operator) profiles
├── booking/         ← Reservation lifecycle
└── rentalunit/      ← Rental unit listings & availability
```

### Feature module internal layout

Each feature module grows its own technical sub-packages **only when needed**:

```
auth/
├── controller/
├── service/
├── repository/
├── entity/
└── dto/
```

> **Rule:** Do **not** create `controller/`, `service/`, `repository/`, `entity/`, or `dto/`
> at the top-level `com.back2kasi` package. Keep them inside their feature module.

---

## 3. Naming Rules

### Classes

| Type | Convention | Example |
|---|---|---|
| Entity | `PascalCase` + noun | `RentalUnit`, `Booking` |
| Repository | Entity name + `Repository` | `RentalUnitRepository` |
| Service (interface) | Entity name + `Service` | `BookingService` |
| Service (impl) | Interface name + `Impl` | `BookingServiceImpl` |
| Controller | Feature name + `Controller` | `AuthController` |
| DTO (request) | Feature + `Request` | `CreateBookingRequest` |
| DTO (response) | Feature + `Response` | `BookingResponse` |
| Exception | Descriptive noun + `Exception` | `ResourceNotFoundException` |
| Config | Purpose + `Config` | `SecurityConfig` |

### Methods

- Use **camelCase**.
- CRUD verbs: `create`, `find`, `findAll`, `update`, `delete`.
- Boolean predicates: `is*`, `has*`, `can*`.

### Constants & Enums

- Constants: `UPPER_SNAKE_CASE`
- Enum values: `UPPER_SNAKE_CASE`

### Database columns / JSON fields

- Database columns: `snake_case` (managed via JPA `@Column(name = "…")`)
- JSON fields exposed in the API: `camelCase`

---

## 4. Java Coding Standards

### Tooling

- Java 21
- Spring Boot 3.x
- Lombok (reduce boilerplate — use `@Getter`, `@Setter`, `@Builder`, `@RequiredArgsConstructor`)
- No `var` in public API signatures; use it freely in method bodies

### Annotations order on a class

```java
@Entity
@Table(name = "rental_units")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RentalUnit { … }
```

### Constructor injection only

```java
// ✅ Correct
@Service
@RequiredArgsConstructor
public class BookingServiceImpl implements BookingService {
    private final BookingRepository bookingRepository;
}

// ❌ Wrong — never use field injection
@Autowired
private BookingRepository bookingRepository;
```

### Use records for DTOs

```java
public record CreateBookingRequest(
    @NotNull UUID rentalUnitId,
    @NotNull LocalDate checkIn,
    @NotNull LocalDate checkOut
) {}
```

### Avoid raw types and unchecked warnings

---

## 5. REST API Standards

### URL Design

| Resource | GET (list) | GET (single) | POST | PUT | DELETE |
|---|---|---|---|---|---|
| Bookings | `/api/v1/bookings` | `/api/v1/bookings/{id}` | `/api/v1/bookings` | `/api/v1/bookings/{id}` | `/api/v1/bookings/{id}` |
| Rental units | `/api/v1/rental-units` | `/api/v1/rental-units/{id}` | … | … | … |

**Rules:**
- Prefix: `/api/v1/`
- Use **kebab-case** for multi-word resources (`rental-units`)
- Use **plural** nouns
- No verbs in URLs (`/bookings/cancel/{id}` ❌ → `PATCH /bookings/{id}` with status in body ✅)
- IDs are `UUID`

### Response envelope

All responses are wrapped in `ApiResponse<T>`:

```json
{
  "success": true,
  "message": "Booking created successfully",
  "data": { … },
  "timestamp": "2025-01-01T12:00:00Z"
}
```

Error response:

```json
{
  "success": false,
  "message": "Rental unit not found",
  "errors": ["rentalUnitId: must not be null"],
  "timestamp": "2025-01-01T12:00:00Z"
}
```

### HTTP Status codes

| Scenario | Code |
|---|---|
| Success (GET / PUT) | `200 OK` |
| Resource created | `201 Created` |
| No content (DELETE) | `204 No Content` |
| Validation error | `400 Bad Request` |
| Unauthenticated | `401 Unauthorized` |
| Forbidden | `403 Forbidden` |
| Not found | `404 Not Found` |
| Server error | `500 Internal Server Error` |

---

## 6. Database Conventions

- Database: **PostgreSQL**
- ORM: **Spring Data JPA / Hibernate**
- Migrations: **Flyway** (to be added)

### Table naming

- `snake_case`, plural: `rental_units`, `bookings`, `business_profiles`

### Column naming

- `snake_case`
- Primary key: always `id UUID DEFAULT gen_random_uuid()`
- Audit columns on every entity: `created_at`, `updated_at`

### Base entity (shared)

```java
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public abstract class BaseEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @CreatedDate
    @Column(updatable = false)
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;
}
```

---

## 7. Git Workflow

### Branch strategy

```
main          ← production-ready code only
  └── develop ← integration branch
        └── feature/auth-login
        └── feature/booking-create
        └── fix/rental-unit-availability-bug
```

### Branch naming

```
feature/<short-description>     e.g. feature/auth-jwt
fix/<short-description>         e.g. fix/booking-date-overlap
chore/<short-description>       e.g. chore/add-devtools
docs/<short-description>        e.g. docs/api-standards
```

### Commit message format (Conventional Commits)

```
<type>(<scope>): <short summary>

feat(auth): add JWT refresh token endpoint
fix(booking): correct overlap validation logic
chore(deps): add spring-boot-devtools
docs: add DEVELOPMENT_STANDARDS.md
```

Types: `feat`, `fix`, `chore`, `docs`, `test`, `refactor`, `style`, `perf`

### Pull Request rules

- PRs go into `develop`, never directly into `main`
- Minimum one reviewer
- All CI checks must pass before merging
- Squash merge preferred to keep history clean

---

## 8. Testing Standards

### Layers

| Layer | Tool | Location |
|---|---|---|
| Unit tests | JUnit 5 + Mockito | `src/test/…` same package as class |
| Integration tests | `@SpringBootTest` + Testcontainers | `src/test/…/integration/` |
| API / slice tests | `@WebMvcTest` | `src/test/…/<feature>/controller/` |

### Naming

```
BookingServiceImplTest        ← unit test for BookingServiceImpl
BookingControllerTest         ← @WebMvcTest slice
BookingIntegrationTest        ← full integration test
```

### Coverage target

- Minimum **80%** line coverage on service layer
- All public controller endpoints must have at least one API test

---

## 9. Error Handling

- All exceptions bubble up to `GlobalExceptionHandler` in `com.back2kasi.common.exception`
- Use custom exceptions: `ResourceNotFoundException`, `BusinessException`, `UnauthorizedException`
- Never return a `500` for a user error (validation, not found, auth)
- Never expose stack traces in API responses (production)

---

## 10. Logging

- Use **SLF4J** via Lombok `@Slf4j`
- Log at `INFO` level for significant business events
- Log at `DEBUG` level for diagnostic/development detail
- Log at `ERROR` level (with exception) for unexpected failures
- Never log passwords, tokens, or PII

```java
@Slf4j
@Service
@RequiredArgsConstructor
public class BookingServiceImpl implements BookingService {

    public BookingResponse createBooking(CreateBookingRequest request) {
        log.info("Creating booking for rentalUnitId={}", request.rentalUnitId());
        // …
    }
}
```

---

*Last updated: 2025-07 | Owner: Back2Kasi Engineering*
