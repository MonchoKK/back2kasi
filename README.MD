# Back2Kasi

> A platform connecting people to affordable township accommodation and rental units.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Tech Stack](#tech-stack)
3. [Project Structure](#project-structure)
4. [Prerequisites](#prerequisites)
5. [Local Development Setup](#local-development-setup)
6. [Running the Application](#running-the-application)
7. [Environment Configuration](#environment-configuration)
8. [API Overview](#api-overview)
9. [Git Workflow](#git-workflow)
10. [Documentation](#documentation)

---

## Project Overview

Back2Kasi is a full-stack platform built to help people find and book rental units in townships. The backend exposes a RESTful API consumed by a mobile/web frontend.

**Current status:** 🚧 In active development

---

## Tech Stack

### Backend (Cloudflare Worker — Production) (`/worker`)

| Technology | Purpose |
|---|---|
| Cloudflare Workers | Serverless Edge Runtime (Free Tier: 100k req/day) |
| Cloudflare D1 | Distributed SQLite Database (Free Tier: 5GB, 5M reads/day) |
| Hono | Ultra-fast Edge Web Framework with TypeScript |
| Web Crypto API (HS256) | Zero-overhead JWT authentication |
| bcryptjs | Password hashing compatible with edge runtime |
| Wrangler | Cloudflare CLI & local simulation |

### Legacy Backend (Spring Boot) (`/backend`)

| Technology | Version | Purpose |
|---|---|---|
| Java | 21 | Language |
| Spring Boot | 3.5.3 | Application framework |
| Spring Data JPA / Hibernate | — | ORM / database access |
| PostgreSQL | 18.x | Relational database |

### Frontend (`/app`)

| Technology | Purpose |
|---|---|
| Flutter / Dart | Cross-platform mobile (Android/iOS) client |
| Provider | State management |
| Flutter Secure Storage | Secure credential storage |

---

## Project Structure

```
back2kasi/
├── worker/                         ← Cloudflare Worker REST API (Active)
│   ├── src/
│   │   ├── index.ts                ← Entrypoint, CORS, error handling
│   │   ├── types.ts                ← Type definitions & DTOs
│   │   ├── lib/                    ← JWT & error utilities
│   │   ├── middleware/             ← Auth middleware
│   │   └── routes/                 ← Auth, Businesses, Rental Units, Bookings
│   ├── migrations/                 ← D1 SQLite database migrations
│   └── wrangler.jsonc              ← Worker & D1 binding configuration
│
├── app/                            ← Flutter mobile application
├── backend/                        ← Original Spring Boot API (reference)
├── docs/                           ← Project-level documentation
└── README.MD
```

---

## Prerequisites

Make sure you have the following installed before starting:

| Tool | Version | Download |
|---|---|---|
| Java JDK | 21 | [adoptium.net](https://adoptium.net) |
| Maven | 3.9+ | [maven.apache.org](https://maven.apache.org) |
| PostgreSQL | 14+ | [postgresql.org](https://www.postgresql.org/download) |
| Git | Latest | [git-scm.com](https://git-scm.com) |

---

## Local Development Setup

### 1. Clone the repository

```bash
git clone https://github.com/MonchoKK/back2kasi.git
cd back2kasi
```

### 2. Create the PostgreSQL database

Open your terminal and run:

```bash
psql -U postgres -c "CREATE DATABASE back2kasi_db;"
```

Or using pgAdmin / any PostgreSQL client — create a database named `back2kasi_db`.

### 3. Configure local credentials

Create the file `backend/src/main/resources/application-local.properties`:

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/back2kasi_db
spring.datasource.username=postgres
spring.datasource.password=YOUR_POSTGRES_PASSWORD
```

> ⚠️ This file is listed in `.gitignore` and will **never** be committed. Do not share it.

---

## Running the Application

From the `backend/` directory:

```bash
cd backend
mvn spring-boot:run
```

The server starts on **`http://localhost:8080`**.

You'll know it's running when you see:

```
Started Back2KasiApplication in ~11s
```

### Useful commands

| Command | Description |
|---|---|
| `mvn spring-boot:run` | Start the app in dev mode |
| `mvn clean spring-boot:run` | Clean build then start |
| `mvn test` | Run all tests |
| `mvn package` | Build a runnable `.jar` |
| `Ctrl + C` | Stop the app |

> **Tip:** Spring DevTools is enabled — the app **auto-restarts** whenever you save a `.java` file.

---

## Environment Configuration

| File | Purpose | Committed? |
|---|---|---|
| `application.properties` | Shared defaults, all environments | ✅ Yes |
| `application-local.properties` | Local DB credentials (overrides defaults) | ❌ No — gitignored |

The active profile is set in `application.properties`:

```properties
spring.profiles.active=local
```

For production, credentials should be supplied via environment variables:

```bash
DB_URL=jdbc:postgresql://host/back2kasi_db
DB_USERNAME=postgres
DB_PASSWORD=secret
```

---

## API Overview

All endpoints are prefixed with `/api/v1/`.

| Resource | Base URL |
|---|---|
| Rental Units | `/api/v1/rental-units` |
| Bookings | `/api/v1/bookings` |
| Auth | `/api/v1/auth` |
| Business Profiles | `/api/v1/businesses` |

Full API standards are documented in [`docs/DEVELOPMENT_STANDARDS.md`](docs/DEVELOPMENT_STANDARDS.md).

---

## Git Workflow

```
main          ← production-ready code only
  └── develop ← integration branch
        └── feature/your-feature-name
```

### Branch naming

```
feature/<short-description>    e.g. feature/auth-jwt
fix/<short-description>        e.g. fix/booking-date-overlap
chore/<short-description>      e.g. chore/add-devtools
docs/<short-description>       e.g. docs/update-readme
```

### Commit format (Conventional Commits)

```
feat(auth): add JWT refresh token endpoint
fix(booking): correct overlap validation logic
chore(deps): add spring-boot-devtools
docs: update README setup instructions
```

---

## Documentation
WTC-LHVJQSJP

| Document | Description |
|---|---|
| [`docs/DEVELOPMENT_STANDARDS.md`](docs/DEVELOPMENT_STANDARDS.md) | Coding conventions, naming rules, API standards, Git workflow |

---

*Built with ☕ and 🏘️ by the Back2Kasi team.*
