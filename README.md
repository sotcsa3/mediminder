# MediMinder - Medication Reminder PWA

A Progressive Web Application for medication and appointment management, built with a Spring Boot backend and PostgreSQL database.

## 🏗️ Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   PWA Frontend  │────▶│  Spring Boot    │────▶│   PostgreSQL    │
│   (Vanilla JS)  │     │   Backend       │     │   Database      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Java 17+
- Maven 3.6+
- PostgreSQL 15+
- Node.js (optional, for development server)
- Docker & Docker Compose (for containerized deployment)

### ⚙️ Environment Setup

Before running the application, copy the example environment file and configure your secrets:
```bash
cp .env.example .env
# Edit .env and supply your Google Client ID, DB passwords, and JWT secret
```

### Option 1: Development Server (Docker Compose)

```bash
# Start all development services
docker-compose up -d

# The API will be available at http://localhost:8080/api
# Open index.html in a browser or use a live server extension
```

### Option 2: Production Server (Docker Compose)

The production setup includes an Nginx reverse proxy, SSL termination, and rate limiting.

```bash
# 1. Generate development SSL certs (Skip if using Let's Encrypt in production)
./scripts/generate-ssl-certs.sh

# 2. Start all production services
docker-compose -f docker-compose.yml -f docker-compose.production.yml up -d
```

### Option 2: Manual Setup

1. **Start PostgreSQL:**
   ```bash
   # Create database
   createdb mediminder
   
   # Or using psql
   psql -U postgres
   CREATE DATABASE mediminder;
   CREATE USER mediminder WITH PASSWORD 'mediminder123';
   GRANT ALL PRIVILEGES ON DATABASE mediminder TO mediminder;
   ```

2. **Run the schema:**
   ```bash
   psql -U mediminder -d mediminder -f backend/src/main/resources/db/schema.sql
   ```

3. **Start the backend:**
   ```bash
   cd backend
   mvn spring-boot:run
   ```

4. **Serve the frontend:**
   ```bash
   # Using Python
   python -m http.server 5500
   
   # Or using Node.js
   npx serve .
   
   # Or use Live Server extension in VS Code
   ```

## 📁 Project Structure

```
.
├── backend/                    # Spring Boot backend
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/mediminder/
│   │   │   │   ├── config/     # Configuration classes
│   │   │   │   ├── controller/ # REST controllers
│   │   │   │   ├── dto/        # Data Transfer Objects
│   │   │   │   ├── entity/     # JPA entities
│   │   │   │   ├── exception/  # Exception handling
│   │   │   │   ├── repository/ # JPA repositories
│   │   │   │   ├── security/   # JWT & Security
│   │   │   │   └── service/    # Business logic
│   │   │   └── resources/
│   │   │       ├── application.yml
│   │   │       └── db/schema.sql
│   │   └── test/
│   ├── pom.xml
│   └── Dockerfile
├── api-config.js              # API configuration
├── api-service.js             # API service layer
├── backend-db.js              # Data layer (replaces supabase-db.js)
├── app.js                     # Main application logic
├── index.html                 # Main HTML file
├── style.css                  # Styles
├── sw.js                      # Service Worker
├── manifest.json              # PWA manifest
├── nginx/                     # Reverse proxy and SSL configuration
├── scripts/                   # Utility scripts (e.g. SSL cert generation)
├── docker-compose.yml         # Development Docker configuration
├── docker-compose.production.yml # Production Docker configuration
├── .env.example               # Environment variables template
└── README.md                  # This file
```

## 🔌 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login
- `POST /api/auth/google` - Google OAuth login
- `GET /api/auth/me` - Get current user

### Medications
- `GET /api/medications` - Get all medications for user
- `POST /api/medications` - Save medications (bulk)
- `DELETE /api/medications` - Delete all medications

### Medication Logs
- `GET /api/med-logs` - Get all logs for user
- `POST /api/med-logs` - Save logs (bulk)
- `DELETE /api/med-logs` - Delete all logs

### Appointments
- `GET /api/appointments` - Get all appointments for user
- `POST /api/appointments` - Save appointments (bulk)
- `DELETE /api/appointments` - Delete all appointments

### Monitoring & Health
- `GET /api/health` - Basic API health check
- `GET /actuator/health` - Detailed application health
- `GET /actuator/prometheus` - Prometheus metrics
- `GET /actuator/info` - Application information

## ⚙️ Configuration

Configuration is primarily managed via environment variables (see `.env.example`).

### Backend Properties Configuration

The backend reads properties from `application.yml`, which overrides defaults with environment variables:
- `JWT_SECRET`: For signing auth tokens
- `CORS_ORIGINS`: Allowed origins for CORS
- `GOOGLE_CLIENT_ID`: For OAuth configuration
- `DB_PASSWORD`: PostgreSQL password

The backend also includes customizable **Rate Limiting** via Spring properties (`app.rate-limit.*`).

### Frontend Configuration (`api-config.js`)

The frontend configures its endpoint and integrations securely via injected variables or fallbacks:

```javascript
const API_BASE_URL = window.API_BASE_URL || 'http://localhost:8080/api';
const GOOGLE_CLIENT_ID = window.GOOGLE_CLIENT_ID || 'YOUR_GOOGLE_CLIENT_ID';
```

## 🔐 Authentication

The application uses JWT (JSON Web Token) authentication:

1. User registers or logs in
2. Server returns a JWT token
3. Token is stored in localStorage
4. Token is sent in `Authorization: Bearer <token>` header for all requests

## 📱 PWA Features

- **Offline Support:** Service worker caches static assets
- **Installable:** Can be installed on mobile devices
- **Push Notifications:** Medication reminders (when permitted)

## 🧪 Development

### Running Tests

```bash
cd backend
mvn test
```

### Building for Production

```bash
# Backend
cd backend
mvn package -DskipTests
java -jar target/mediminder-backend-1.0.0.jar

# Frontend - just serve the static files
```

## 🔄 Migration from Supabase

This version has been migrated from Supabase to a custom Spring Boot backend:

| Supabase | Spring Boot Backend |
|----------|---------------------|
| `supabase-config.js` | `api-config.js` |
| `supabase-db.js` | `backend-db.js` + `api-service.js` |
| Supabase Auth | JWT Authentication |
| Supabase Realtime | Polling (can add WebSockets) |
| Row Level Security | Spring Security |

## 📝 License

MIT License

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request
