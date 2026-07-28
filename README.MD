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

### Backend (`/backend`)

| Technology | Version | Purpose |
|---|---|---|
| Java | 21 | Language |
| Spring Boot | 3.5.3 | Application framework |
| Spring Data JPA | — | ORM / database access |
| Hibernate | 6.6.x | JPA implementation |
| PostgreSQL | 18.x | Relational database |
| Lombok | — | Boilerplate reduction |
| Spring Validation | — | Request validation |
| Spring DevTools | — | Auto-restart on save |
| Maven | 3.x | Build tool |

### Frontend (`/app`)

> To be documented.

---

## Project Structure

```
back2kasi/
├── backend/                        ← Spring Boot REST API
│   └── src/main/java/com/back2kasi/
│       ├── Back2KasiApplication.java
│       ├── config/                 ← Cross-cutting config (Security, CORS, …)
│       ├── common/                 ← Shared utilities, exceptions, response wrapper
│       ├── auth/                   ← Authentication & authorisation
│       ├── business/               ← Business/owner profiles
│       ├── booking/                ← Reservation lifecycle
│       └── rentalunit/             ← Rental unit listings & availability
│
├── app/                            ← Mobile / frontend application
├── docs/                           ← Project-level documentation
│   └── DEVELOPMENT_STANDARDS.md
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

| Document | Description |
|---|---|
| [`docs/DEVELOPMENT_STANDARDS.md`](docs/DEVELOPMENT_STANDARDS.md) | Coding conventions, naming rules, API standards, Git workflow |

---

*Built with ☕ and 🏘️ by the Back2Kasi team.*
