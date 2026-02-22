# MediMinder Production Readiness Audit

**Dátum:** 2026-02-22  
**Verzió:** 1.0.0  
**Auditor:** GitHub Copilot (Claude Opus 4.6)

---

## Összefoglaló

| Kategória | Pontszám | Minimum prod-hoz | Állapot |
|-----------|----------|-------------------|---------|
| Biztonság | 6.5/10 | 8/10 | 🔴 Nem kész |
| Terhelhetőség | 3/10 | 6/10 | 🔴 Nem kész |
| Tesztelés | 1/10 | 5/10 | 🔴 Kritikus |
| Infrastruktúra | 5/10 | 7/10 | 🟡 Részleges |
| Kódminőség | 7/10 | 7/10 | ✅ Elfogadható |
| **Összesített production readiness** | **~40%** | **65%+** | **🔴 Nem deployolható** |

---

## 1. KRITIKUS Biztonsági Sérülékenységek

### 1.1 🔴 Rate Limiter nem működik — `tryConsume()` mindig `true`

**Fájl:** `backend/src/main/java/com/mediminder/security/RateLimitFilter.java` (120-135. sor)

**Probléma:** A `RateLimitBucket.tryConsume()` metódus növeli a számlálót, de **soha nem hasonlítja össze a maximális kérésszámmal** — mindig `true`-t ad vissza. A rate limiter gyakorlatilag ki van kapcsolva.

```java
// JELENLEGI (HIBÁS) — mindig true-t ad vissza
public synchronized boolean tryConsume() {
    long now = System.currentTimeMillis();
    if (now - windowStart > windowSeconds * 1000L) {
        windowStart = now;
        count.set(0);
    }
    count.incrementAndGet();
    return true; // ← HIBA: soha nem ellenőrzi a limitet!
}
```

**Javítás:**
```java
public synchronized boolean tryConsume(int maxRequests) {
    long now = System.currentTimeMillis();
    if (now - windowStart > windowSeconds * 1000L) {
        windowStart = now;
        count.set(0);
    }
    if (count.get() >= maxRequests) {
        return false;
    }
    count.incrementAndGet();
    return true;
}
```

**Hatás:** Bárki korlátlan számú kérést küldhet — DDoS és brute-force támadás lehetséges.

---

### 1.2 🔴 Google Login Fiókatvétel (Account Takeover)

**Fájl:** `backend/src/main/java/com/mediminder/service/AuthService.java` — `handleGoogleLogin()` metódus

**Probléma:** Ha egy Google fiókkal bejelentkező felhasználó email címe megegyezik egy meglévő **lokális** (jelszóval regisztrált) fiókkal, a rendszer csendben:
1. Átírja a `provider` mezőt `"local"`-ról `"google"`-re
2. Felülírja a `fullName`-et
3. Kiadja a JWT tokent

**Támadási forgatókönyv:**
1. Áldozat regisztrál `victim@gmail.com` email + jelszó kombinációval
2. Támadó birtokolja a `victim@gmail.com` Google fiókot (vagy létrehozza)
3. Támadó a Google login-nal belép → átveszi a fiókot
4. Az áldozat jelszavas belépése továbbra is működhet, de a fiók már kompromittált

**Javítás:** Ha az email már létezik más providerrel, ne engedje az átvételt — adjon hibaüzenetet, vagy kérje a meglévő fiók megerősítését.

---

### 1.3 🔴 `@Valid` nem kényszeríti ki a validációt List elemekre

**Fájl:** Minden controller (`MedicationController`, `AppointmentController`, `MedLogController`)

**Probléma:** A kontrollerek `@Valid @RequestBody List<MedicationDTO>` mintát használnak. Spring Boot-ban a `@Valid` annotáció **nem propagálódik a lista elemeire** automatikusan. A `@NotBlank` annotációk a DTO mezőkön **nem futnak le**.

**Érintett endpointok:**
- `POST /api/v1/medications` — `@Valid @RequestBody List<MedicationDTO>`
- `POST /api/v1/appointments` — `@Valid @RequestBody List<AppointmentDTO>`
- `POST /api/v1/med-logs` — `@Valid @RequestBody List<MedLogDTO>`

**Javítás:** `@Validated` annotáció hozzáadása a controller osztályokhoz:
```java
@RestController
@RequestMapping("/v1/medications")
@RequiredArgsConstructor
@Validated  // ← EZ HIÁNYZIK
public class MedicationController { ... }
```

**Hatás:** Üres név, dózis, frekvencia stb. bekerülhet az adatbázisba.

---

### 1.4 🔴 `hibernate.ddl-auto: update` production-ben

**Fájl:** `backend/src/main/resources/application.yml` (17. sor)

**Probléma:** A `ddl-auto: update` beállítás automatikusan módosíthatja a séma struktúrát induláskor. Production-ben ez:
- Adatvesztést okozhat (oszlop típus változás)
- Értesítés nélkül változtatja a sémát
- Nem reprodukálható, nem verziókezelt
- Nem rollback-elhető

**Javítás:** ~~Flyway vagy Liquibase bevezetése, és `ddl-auto: validate` vagy `none` beállítás.~~ ✅ Megoldva.

---

## 2. KÖZEPES Biztonsági Problémák

### 2.1 🟡 Konténer root-ként fut

**Fájl:** `backend/Dockerfile`

**Probléma:** Nincs `USER` direktíva — az alkalmazás root jogosultsággal fut a konténerben. Ha bármelyik sérülékenységet kihasználják, a támadó root hozzáférést kap a konténerhez.

**Javítás:**
```dockerfile
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
```

---

### 2.2 🟡 Email címek PII logolása

**Fájl:** `backend/src/main/java/com/mediminder/controller/AuthController.java` (28., 34. sor)

```java
log.info("Register request for email: {}", request.getEmail());
log.info("Login request for email: {}", request.getEmail());
```

**Probléma:** GDPR és egyéb adatvédelmi szabályok szerint a PII (personally identifiable information) nem kerülhet plaintext-ben a logokba.

**Javítás:** Email maszkolása a logokban, pl. `s***@gmail.com`.

---

### 2.3 🟡 Admin email hardkódolva a frontend-ben

**Fájl:** `app.js` (6. sor)

```javascript
const ADMIN_EMAIL = 'sotcsa+admin@gmail.com';
```

**Probléma:** Bárki megtekintheti a kliens kódot — az admin email cím nyilvános. Ez social engineering támadáshoz használható.

---

### 2.4 🟡 Nginx rate limiting kikommentelve

**Fájl:** `nginx/nginx.conf` (118. sor)

```nginx
# Rate limiting (optional - comment out if not needed)
# limit_req zone=api_limit burst=20 nodelay;
```

A zone definiálva van (`limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;`), de az alkalmazás nincs rá kötve. Az alkalmazásszintű rate limiter sem működik (lásd 1.1), tehát **semmilyen rate limiting nincs érvényben**.

---

### 2.5 🟡 Rate limiter user ID soha nincs beállítva

**Fájl:** `backend/src/main/java/com/mediminder/security/RateLimitFilter.java` (68. sor)

```java
String userId = (String) request.getAttribute("userId");
```

A `userId` request attribute-ot senki nem állítja be. A `JwtAuthenticationFilter` a `SecurityContextHolder`-be teszi az authentikációt, de nem állít be request attribute-ot. Így az autentikált felhasználók mindig IP-alapú rate limiting alá kerülnének (ha a rate limiter egyáltalán működne).

---

### 2.6 🟡 Autentikációs hibák 400-as kódot adnak 401 helyett

**Fájl:** `backend/src/main/java/com/mediminder/service/AuthService.java`

```java
throw new RuntimeException("Invalid email or password");
```

A `GlobalExceptionHandler` ezt `RuntimeException`-ként kezeli és 400 Bad Request-et ad vissza. Az RFC 7235 szerint ez 401 Unauthorized kellene legyen. Saját exception típus kellene.

---

## 3. Terhelhetőségi Problémák

### 3.1 Becsült kapacitás

| Komponens | Jelenlegi limit | Megjegyzés |
|-----------|----------------|------------|
| **HikariCP connection pool** | 10 (default) | Nincs konfigurálva |
| **JVM memória** | Korlátlan (konténer limit) | Nincs `-Xmx` a Dockerfile-ban |
| **Egyidejű felhasználók** | ~50-100 | Connection pool és memória korlát |
| **Rate limiting** | ∞ (nem működik) | Bárki korlátlan kérést küldhet |

### 3.2 🔴 Nincs pagination

**Érintett fájlok:** Minden service (`MedicationService`, `AppointmentService`, `MedLogService`)

Minden endpoint az **összes** rekordot visszaadja egy felhasználóhoz:
```java
public List<MedicationDTO> getMedications(String userId) {
    return medicationRepository.findByUserId(userId).stream()
            .map(this::toDTO)
            .collect(Collectors.toList());
}
```

Egy aktív felhasználó hónapok után több ezer `MedLog` bejegyzéssel rendelkezhet — egyetlen GET kérés mindet memóriába tölti.

**Javítás:** `Pageable` paraméter bevezetése a repository-kba és endpoint-okba.

---

### 3.3 🟡 Nincs graceful shutdown

**Fájl:** `backend/src/main/resources/application.yml`

Hiányzik:
```yaml
server:
  shutdown: graceful

spring:
  lifecycle:
    timeout-per-shutdown-phase: 30s
```

Deploy közben a folyamatban lévő kérések megszakadhatnak.

---

### 3.4 🟡 Nincs JVM memória konfiguráció

**Fájl:** `backend/Dockerfile`

```dockerfile
ENTRYPOINT ["java", "-jar", "app.jar"]
```

Hiányzik: `-Xmx`, `-Xms`, `-XX:+UseContainerSupport`, `-XX:MaxRAMPercentage`.

---

### 3.5 🟡 Connection Pool nem konfigurált

**Fájl:** `backend/src/main/resources/application.yml`

Spring Boot default HikariCP beállítások (max 10 connection). Production-ben explicit konfiguráció szükséges:

```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
      leak-detection-threshold: 60000
```

---

## 4. Tesztelési Hiányosságok

### 4.1 Backend tesztek

| Teszt típus | Állapot | Részlet |
|-------------|---------|--------|
| Unit tesztek (Service) | ❌ Nincs | 0 db service teszt |
| Unit tesztek (Security) | ❌ Nincs | JWT provider, filter-ek teszteletlen |
| Integrációs tesztek | ❌ Nincs | Egyetlen controller endpoint sincs tesztelve |
| Context load | ✅ 1 db | `MediMinderBackendApplicationTests.contextLoads()` |

**Kódlefedettség:** ~0%

### 4.2 Frontend tesztek

| Teszt típus | Állapot | Részlet |
|-------------|---------|--------|
| api-service.js | ✅ 4 teszt | `setToken`, `getToken`, `removeToken`, GET kérés |
| app.js (1714 sor) | ❌ Nincs | Teljes UI logika teszteletlen |
| E2E tesztek | ❌ Nincs | Nincs Playwright/Cypress |
| Coverage threshold | ❌ Nincs | `vitest.config.js`-ben nincs beállítva |

### 4.3 Hiányzó teszt stratégia (ajánlás)

**Phase 1 — Minimum backend tesztek:**
- `AuthService` unit tesztek (regisztráció, login, Google login edge case-ek)
- `JwtTokenProvider` unit tesztek (generálás, validáció, lejárat)
- `RateLimitFilter` unit tesztek (limit elérés, window reset)
- Controller integrációs tesztek `@WebMvcTest`-tel

**Phase 2 — Frontend:**
- `app.js` modularizálás (jelenleg 1714 soros monolitikus fájl)
- Kritikus flow-k E2E tesztelése (regisztráció → login → gyógyszer hozzáadás)

---

## 5. Adatbázis Problémák

### 5.1 ✅ Migration tool bevezetve (Flyway)

~~Jelenleg: `hibernate.ddl-auto: update` + kézi `schema.sql`.~~

**Megoldva:** Flyway bevezetve `V1__initial_schema.sql` baseline migrációval. `ddl-auto` átállítva `validate`-re. Docker Compose fájlokból eltávolítva a kézi `schema.sql` mount — a séma kezelését mostantól Flyway végzi.

### 5.2 🟡 Dátumok string-ként tárolva

**Érintett fájlok:**
- `MedLog` entity: `date` (VARCHAR), `time` (VARCHAR)
- `Appointment` entity: `date` (VARCHAR), `time` (VARCHAR)

**Probléma:** Nincs DB-szintű dátum validáció, rendezés és tartomány lekérdezés nem hatékony.

### 5.3 🟡 `MedLog.medId` nincs foreign key-jel kötve

**Fájl:** `backend/src/main/java/com/mediminder/entity/MedLog.java`

A `medId` mező sima `String` — nincs `@ManyToOne` kapcsolat a `Medication` entity-vel. Ha egy gyógyszert törölnek, az árva log bejegyzések megmaradnak.

### 5.4 🟡 Nincs backup stratégia

A `docker-compose.production.yml` PostgreSQL volume-ot használ, de nincs:
- Automatikus backup (pg_dump cron)
- Point-in-time recovery (WAL archiving)
- Backup validáció / restore teszt

---

## 6. Infrastruktúra Állapot

| Elem | Állapot | Megjegyzés |
|------|---------|------------|
| Docker multi-stage build | ✅ | Maven + JRE-alpine |
| SSL/TLS (Nginx) | ✅ | TLSv1.2/1.3, strong ciphers |
| Security headers | ✅ | HSTS, CSP, X-Frame-Options, X-XSS-Protection |
| Actuator monitoring | ✅ | Prometheus + health, IP-restricted |
| Gzip compression | ✅ | Nginx-ben konfigurálva |
| API versioning | ✅ | `/v1/` prefix |
| Caffeine cache | ✅ | 5 perc TTL, max 1000 elem |
| CI/CD pipeline | ❌ | Nincs (kézi deploy) |
| DB backup | ❌ | Nincs stratégia |
| Flyway/Liquibase | ✅ | V1 baseline migráció kész |
| Container health check | ❌ | Dockerfile-ban nincs `HEALTHCHECK` |
| Non-root container | ❌ | Root-ként fut |

---

## 7. Kódminőségi Észrevételek

### 7.1 Service réteg — "replace all" pattern

A `MedicationService`, `AppointmentService`, `MedLogService` azonos mintát követi:
- `GET` → összes elem lekérése
- `POST` → **összes meglévő törlése** + új lista mentése
- `DELETE` → összes törlése

Nincs egyedi CRUD (GET/PUT/DELETE by ID). Ez:
- Felesleges adatbázis terhelést okoz
- Conflict kezelést nehezíti multi-device sync esetén
- Audit logging-ot lehetetlenné teszi

### 7.2 Frontend monolitikus struktúra

Az `app.js` 1714 soros egyetlen fájl — nincs modularizáció, nincs build process (minification, bundling, tree-shaking). A `sw.js` verziószáma kézzel kell szinkronizálni az `app.js`-sel.

### 7.3 Swagger endpoint-ok biztonsági szabályai érvénytelenek

A `SecurityConfig`-ban engedélyezve van a `/swagger-ui/**` és `/v3/api-docs/**`, a `springdoc-openapi` dependency benne van a `pom.xml`-ben — ez rendben van, de production-ben érdemes lenne ezeket is korlátozni.

---

## 8. Javítási Prioritások (Deploy előtt kötelező)

### Tier 1 — Blokkoló hibák (deploy előtt KÖTELEZŐ)

| # | Probléma | Fájl | Becsült effort |
|---|----------|------|----------------|
| 1 | Rate limiter `tryConsume()` javítás | `RateLimitFilter.java` | 30 perc |
| 2 | Google login fiók átvétel védelme | `AuthService.java` | 1 óra |
| 3 | `@Validated` hozzáadása controllerekhez | `*Controller.java` | 15 perc |
| 4 | ~~`ddl-auto: update` → `validate` + Flyway~~ | ~~`application.yml` + `pom.xml`~~ | ✅ Kész |
| 5 | Nginx rate limit aktiválás | `nginx.conf` | 5 perc |

### Tier 2 — Fontos (deploy után 1 héten belül)

| # | Probléma | Fájl | Becsült effort |
|---|----------|------|----------------|
| 6 | Graceful shutdown konfiguráció | `application.yml` | 15 perc |
| 7 | JVM memória flags + non-root user | `Dockerfile` | 30 perc |
| 8 | HikariCP pool tuning | `application.yml` | 30 perc |
| 9 | Auth 401 response (saját exception) | `AuthService.java` + handler | 1 óra |
| 10 | PII maszkolás logokban | `AuthController.java` | 30 perc |

### Tier 3 — Tervezendő (1 hónapon belül)

| # | Probléma | Becsült effort |
|---|----------|----------------|
| 11 | Pagination bevezetése | 1 nap |
| 12 | Backend unit + integrációs tesztek | 3-5 nap |
| 13 | DB backup stratégia (pg_dump cron) | 1 nap |
| 14 | CI/CD pipeline (GitHub Actions) | 1 nap |
| 15 | Frontend modularizáció + build | 3-5 nap |
| 16 | Dátum mezők migrálása VARCHAR → DATE/TIME | 1 nap |
| 17 | MedLog.medId foreign key + cascade | 2 óra |

---

## 9. Mi működik jól

- ✅ Modern Spring Boot 3.2.2 + Java 17 stack
- ✅ JWT autentikáció erős secret validációval
- ✅ DTO pattern — entity-k nem kerülnek közvetlenül a response-ba
- ✅ Réteges architektúra (Controller → Service → Repository)
- ✅ Global exception handling validációs hibákkal
- ✅ Nginx SSL termination + security headerek
- ✅ Actuator/Prometheus monitoring (IP-restricted)
- ✅ Caffeine in-memory cache
- ✅ API versioning (`/v1/`)
- ✅ PWA Service Worker offline támogatás
- ✅ XSS védelem (`escapeHtml()`)
- ✅ Docker multi-stage build
- ✅ PostgreSQL indexek a kulcs oszlopokon
