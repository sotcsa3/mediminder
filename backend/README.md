# MediMinder Backend

Spring Boot REST API for the MediMinder medication reminder application. Provides authentication (email/password and Google OAuth2), and CRUD operations for medications, medication logs, and appointments.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Spring Boot 3.2.2 |
| Language | Java 17 |
| Build Tool | Maven 3.9 |
| Database | PostgreSQL 15 |
| ORM | Spring Data JPA / Hibernate |
| Security | Spring Security + JWT (JJWT 0.12.3) |
| OAuth2 | Google OAuth2 Client |
| Container | Docker |

## Project Structure

```
backend/
├── src/
│   └── main/
│       ├── java/com/mediminder/
│       │   ├── config/          # CORS, JWT properties
│       │   ├── controller/      # REST controllers
│       │   ├── dto/             # Request/Response DTOs
│       │   ├── entity/          # JPA entities
│       │   ├── exception/       # Global exception handler
│       │   ├── repository/      # Spring Data JPA repositories
│       │   ├── security/        # JWT filter, token provider, user principal
│       │   ├── service/         # Business logic
│       │   └── MediMinderApplication.java
│       └── resources/
│           ├── application.yml
│           └── db/schema.sql    # PostgreSQL DDL (tables, indexes, triggers)
├── Dockerfile                   # Multi-stage Docker build
└── pom.xml
```

## API Endpoints

All routes are prefixed with `/api`.

### Auth — `/api/auth`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/auth/register` | No | Register with email + password |
| POST | `/auth/login` | No | Login, returns JWT token |
| POST | `/auth/google` | No | Google OAuth2 login/register |
| GET | `/auth/me` | JWT | Get current user info |

### Medications — `/api/medications`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/medications` | JWT | List all medications for user |
| POST | `/medications` | JWT | Batch save/sync medications |
| DELETE | `/medications` | JWT | Delete all user medications |

### Medication Logs — `/api/med-logs`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/med-logs` | JWT | List all logs for user |
| POST | `/med-logs` | JWT | Batch save/sync logs |
| DELETE | `/med-logs` | JWT | Delete all user logs |

### Appointments — `/api/appointments`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/appointments` | JWT | List all appointments for user |
| POST | `/appointments` | JWT | Batch save/sync appointments |
| DELETE | `/appointments` | JWT | Delete all user appointments |

### Health

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/health` | No | Service health check |

---

## Prerequisites

- **Java 17** (JDK) — [Download](https://adoptium.net/)
- **Maven 3.9+** — [Download](https://maven.apache.org/download.cgi), or use the Maven wrapper if added
- **PostgreSQL 15** — running locally, or via Docker
- **Docker** (optional) — for containerised setup

Check versions:

```bash
java -version
mvn -version
psql --version
docker --version
```

---

## Environment Variables

| Variable | Required | Default (dev only) | Description |
|----------|----------|--------------------|-------------|
| `JWT_SECRET` | Yes | `mediminder-jwt-secret-key-change-in-production-min-256-bits` | HMAC secret, min 256-bit string. **Change in production.** |
| `GOOGLE_CLIENT_ID` | For Google login | `your-google-client-id` | Google OAuth2 client ID |
| `GOOGLE_CLIENT_SECRET` | For Google login | `your-google-client-secret` | Google OAuth2 client secret |
| `CORS_ORIGINS` | No | `http://localhost:5500,http://localhost:3000,http://127.0.0.1:5500` | Comma-separated allowed origins |
| `SPRING_DATASOURCE_URL` | No | `jdbc:postgresql://localhost:5432/mediminder` | Override DB URL (useful in Docker) |
| `SPRING_DATASOURCE_USERNAME` | No | `mediminder` | Database username |
| `SPRING_DATASOURCE_PASSWORD` | No | `mediminder123` | Database password |

Export variables for local development:

```bash
export JWT_SECRET="your-very-long-secret-key-at-least-256-bits"
export GOOGLE_CLIENT_ID="your-google-client-id"
export GOOGLE_CLIENT_SECRET="your-google-client-secret"
```

---

## Local Development Setup

### 1. Start PostgreSQL

**Option A — Docker (recommended):**

```bash
# From the project root (not the backend folder)
docker-compose up postgres -d
```

This starts PostgreSQL and runs `db/schema.sql` automatically on first boot.

**Option B — Local PostgreSQL:**

```bash
# Create database and user
psql -U postgres -c "CREATE USER mediminder WITH PASSWORD 'mediminder123';"
psql -U postgres -c "CREATE DATABASE mediminder OWNER mediminder;"

# Apply schema
psql -U mediminder -d mediminder -f src/main/resources/db/schema.sql
```

### 2. Configure application

The default `application.yml` connects to `localhost:5432` with user `mediminder` / `mediminder123`. No changes needed if using the Docker Compose setup above.

To override any setting without editing the YAML, export the corresponding environment variable (see table above) or create a local `application-local.yml` and run with `-Dspring.profiles.active=local`.

### 3. Run the application

```bash
# From the backend/ directory
mvn spring-boot:run
```

Or with explicit environment variables:

```bash
JWT_SECRET="my-secret" GOOGLE_CLIENT_ID="xxx" mvn spring-boot:run
```

The API is available at `http://localhost:8080/api`.

---

## Build

### Compile and package (JAR)

```bash
mvn clean package -DskipTests
```

The fat JAR is created at `target/mediminder-backend-1.0.0.jar`.

### Run the JAR directly

```bash
java -jar target/mediminder-backend-1.0.0.jar
```

Pass environment variables as JVM system properties if needed:

```bash
java -DJWT_SECRET="my-secret" -jar target/mediminder-backend-1.0.0.jar
```

---

## Testing

Tests use an **H2 in-memory database** (configured in test scope), so no running PostgreSQL is needed.

### Run all tests

```bash
mvn test
```

### Run tests and generate a report

```bash
mvn verify
```

The Surefire report is written to `target/surefire-reports/`.

### Skip tests during build

```bash
mvn clean package -DskipTests
```

---

## Docker

### Build the image (standalone)

```bash
# From the backend/ directory
docker build -t mediminder-backend:latest .
```

The Dockerfile uses a multi-stage build:
1. **Build stage** — `maven:3.9-eclipse-temurin-17` compiles and packages the JAR.
2. **Runtime stage** — `eclipse-temurin:17-jre-alpine` runs the lightweight JRE image.

### Run the container

A running PostgreSQL instance is required. Pass its address via environment variables:

```bash
docker run -d \
  --name mediminder-backend \
  -p 8080:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://<db-host>:5432/mediminder \
  -e SPRING_DATASOURCE_USERNAME=mediminder \
  -e SPRING_DATASOURCE_PASSWORD=mediminder123 \
  -e JWT_SECRET=your-secret-key \
  -e GOOGLE_CLIENT_ID=your-google-client-id \
  -e GOOGLE_CLIENT_SECRET=your-google-client-secret \
  -e CORS_ORIGINS=http://localhost:3000 \
  mediminder-backend:latest
```

---

## Docker Compose (full stack)

The `docker-compose.yml` in the **project root** starts both PostgreSQL and the backend together:

```bash
# From the project root
docker-compose up --build
```

Services:
- `postgres` — PostgreSQL 15, port `5432`, data persisted in `postgres_data` volume. Schema is initialised automatically on first run.
- `backend` — Spring Boot app, port `8080`. Waits for PostgreSQL to pass its health check before starting.

Stop and remove containers:

```bash
docker-compose down
```

Remove containers **and** the database volume (full reset):

```bash
docker-compose down -v
```

---

## Production Deployment

### Checklist

- [ ] Set a strong, random `JWT_SECRET` (at least 256-bit / 32 characters).
- [ ] Set real `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` from [Google Cloud Console](https://console.cloud.google.com/).
- [ ] Restrict `CORS_ORIGINS` to your production domain(s) only.
- [ ] Use a managed PostgreSQL service (e.g., AWS RDS, Supabase, Neon) and set `SPRING_DATASOURCE_*` accordingly.
- [ ] Change the default database password (`mediminder123`).
- [ ] Run behind a reverse proxy (Nginx, Caddy, or a cloud load balancer) with TLS/HTTPS.
- [ ] Do **not** expose port 5432 publicly.
- [ ] Set `logging.level.com.mediminder=INFO` (or `WARN`) in production to reduce log verbosity.

### Example: deploy with Docker on a VM

```bash
# Pull or build image, then run:
docker run -d \
  --restart unless-stopped \
  --name mediminder-backend \
  -p 127.0.0.1:8080:8080 \   # bind to loopback; let Nginx proxy externally
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://db.example.com:5432/mediminder \
  -e SPRING_DATASOURCE_USERNAME=mediminder \
  -e SPRING_DATASOURCE_PASSWORD=<strong-password> \
  -e JWT_SECRET=<min-256-bit-random-string> \
  -e GOOGLE_CLIENT_ID=<prod-client-id> \
  -e GOOGLE_CLIENT_SECRET=<prod-client-secret> \
  -e CORS_ORIGINS=https://app.example.com \
  mediminder-backend:latest
```

---

## Database Schema

The schema is defined in [src/main/resources/db/schema.sql](src/main/resources/db/schema.sql). Hibernate is configured with `ddl-auto: update`, so tables are created/updated automatically on startup. For production it is safer to manage schema changes manually or with a migration tool (e.g., Flyway).

### Tables

| Table | Primary Key | Notes |
|-------|-------------|-------|
| `users` | UUID (VARCHAR 36) | Supports local and Google OAuth2 users |
| `medications` | String (VARCHAR 50) | `times` stored as JSONB array |
| `med_logs` | String (VARCHAR 50) | `date` VARCHAR YYYY-MM-DD, `time` VARCHAR HH:MM |
| `appointments` | String (VARCHAR 50) | `status`: pending / done / missed |

All child tables have `ON DELETE CASCADE` foreign keys to `users`. Indexes are created on `user_id` and date columns for query performance.

---

## Authentication Flow

**Email/Password:**

1. `POST /api/auth/register` — password is hashed with BCrypt and stored.
2. `POST /api/auth/login` — credentials verified, JWT returned (valid 24 h).
3. Client sends `Authorization: Bearer <token>` on subsequent requests.

**Google OAuth2:**

1. Frontend completes Google sign-in and sends `email`, `googleId`, `fullName` to `POST /api/auth/google`.
2. Backend creates or links the user account and returns a JWT token.

---

## Common Issues

**`Connection refused` to PostgreSQL**
Ensure PostgreSQL is running and the datasource URL matches. For Docker Compose, use the service name `postgres` as the host instead of `localhost`.

**`JWT signature does not match`**
The `JWT_SECRET` used to sign the token must match the one used to verify it. Restarting the app with a new secret invalidates all existing tokens.

**`CORS error` in browser**
Add the frontend origin to `CORS_ORIGINS`. Multiple origins are comma-separated.

**`403 Forbidden` on a protected endpoint**
Ensure the `Authorization: Bearer <token>` header is present and the token has not expired (24-hour lifetime).