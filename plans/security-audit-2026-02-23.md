# MediMinder Biztonsági és Production Readiness Audit

**Dátum:** 2026-02-23  
**Verzió:** 2.1.32  
**Auditor:** GitHub Copilot (Claude Opus 4.6)

---

## Összefoglaló

| Súlyosság | Új találat | Már ismert (nem fixált) | Összesen |
|-----------|-----------|------------------------|----------|
| KRITIKUS  | 1         | 0                      | 1        |
| MAGAS     | 5         | 2                      | 7        |
| KÖZEPES   | 5         | 6                      | 11       |
| ALACSONY  | 3         | 2                      | 5        |
| **Összesen** | **14** | **10**                | **24**   |

**Összesített production readiness:** ~55% → deploy előtt legalább a KRITIKUS és MAGAS szintű hibák javítása szükséges.

---

## ÚJ Találatok

### #1 — KRITIKUS — Google OAuth token nincs szerveroldalon verifikálva

| Mező | Érték |
|------|-------|
| **Súlyosság** | KRITIKUS |
| **Kategória** | Biztonság — Autentikáció bypass |
| **Fájl** | `backend/src/main/java/com/mediminder/controller/AuthController.java` (42-56. sor) |
| **Állapot** | 🔴 Nyitott |

**Leírás:**  
A `/v1/auth/google` endpoint elfogadja a kliens által küldött `{email, googleId, fullName}` JSON body-t és közvetlenül létrehoz/bejelentkeztet felhasználókat **anélkül, hogy a Google ID tokent valaha ellenőrizné a Google szervereivel**.

```java
@PostMapping("/google")
public ResponseEntity<AuthResponse> googleLogin(@RequestBody Map<String, String> request) {
    String email = request.get("email");
    String googleId = request.get("googleId");
    // ⚠️ Nincs Google token verifikáció!
    AuthResponse response = authService.handleGoogleLogin(email, googleId, fullName);
```

**Hatás:** Teljes autentikáció bypass. Bárki beléphet bármilyen Google-fiókkal — egyetlen cURL paranccsal:
```bash
curl -X POST /api/v1/auth/google \
  -d '{"email":"victim@gmail.com","googleId":"fake","fullName":"Attacker"}'
```

**Javítás:** Google `google-api-client` library-vel ID token verifikáció bevezetése (`GoogleIdTokenVerifier`). A kliens a Google Sign-In ID tokent küldi, a szerver ezt validálja Google felé.

---

### #2 — MAGAS — Rate Limit Filter a JWT Auth Filter előtt fut

| Mező | Érték |
|------|-------|
| **Súlyosság** | MAGAS |
| **Kategória** | Biztonság — Rate Limiting |
| **Fájl** | `backend/src/main/java/com/mediminder/config/SecurityConfig.java` (46-47. sor) |
| **Állapot** | 🔴 Nyitott |

**Leírás:**  
A Spring Security filter chain-ben:
```java
.addFilterBefore(rateLimitFilter, UsernamePasswordAuthenticationFilter.class)
.addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
```
Az `addFilterBefore` logikája miatt a sorrend: `JwtAuth → RateLimit → UsernamePassword...`. Valójában a RateLimitFilter a JWT **után** kellene fusson ahhoz, hogy a `userId` attribútum elérhető legyen (amit a JwtAuthFilter állít be). Jelenleg a `getClientIdentifier()` gyakran az IP-re esik vissza, ezért az autentikált felhasználók is az alacsonyabb (20 req/min) limitet kapják.

**Javítás:** A filter sorrendet meg kell fordítani, hogy a JwtAuth filter futtasson először, utána a RateLimit.

---

### #3 — MAGAS — Rate Limiter memóriaszivárgás

| Mező | Érték |
|------|-------|
| **Súlyosság** | MAGAS |
| **Kategória** | Teljesítmény — Memória |
| **Fájl** | `backend/src/main/java/com/mediminder/security/RateLimitFilter.java` (22. sor) |
| **Állapot** | 🔴 Nyitott |

**Leírás:**  
```java
private final ConcurrentHashMap<String, RateLimitBucket> buckets = new ConcurrentHashMap<>();
```
A bucket-ek IP/userId alapján jönnek létre és **soha nem törlődnek**. Nincs TTL, nincs scheduled cleanup, nincs max méret korlát. Production-ben minden egyedi látogató permanens entry-t hoz létre → korlátlan heap memória fogyasztás.

**Javítás:** Caffeine cache használata TTL-lel (pl. `expireAfterAccess(windowSeconds, SECONDS)`), vagy scheduled task ami a lejárt bucket-eket takarítja.

---

### #4 — MAGAS — Login endpoint user existence enumeration

| Mező | Érték |
|------|-------|
| **Súlyosság** | MAGAS |
| **Kategória** | Biztonság — Information Disclosure |
| **Fájl** | `backend/src/main/java/com/mediminder/service/AuthService.java` (53-57. sor) |
| **Állapot** | 🔴 Nyitott |

**Leírás:**  
```java
User user = userRepository.findByEmail(request.getEmail())
        .orElseThrow(() -> new ResourceNotFoundException("User not found"));
if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
    throw new AuthenticationException("Invalid email or password");
}
```
Két különböző hibaüzenet ("User not found" vs "Invalid email or password") lehetővé teszi, hogy támadók megállapítsák, mely email címek léteznek a rendszerben.

**Javítás:** Mindkét esetre ugyanazt a generikus üzenetet kell visszaadni: "Invalid email or password".

---

### #5 — MAGAS — RuntimeException handler belső részleteket szivárogtat

| Mező | Érték |
|------|-------|
| **Súlyosság** | MAGAS |
| **Kategória** | Biztonság — Information Disclosure |
| **Fájl** | `backend/src/main/java/com/mediminder/exception/GlobalExceptionHandler.java` (63-67. sor) |
| **Állapot** | 🔴 Nyitott |

**Leírás:**  
```java
@ExceptionHandler(RuntimeException.class)
public ResponseEntity<?> handleRuntimeException(RuntimeException e) {
    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(Map.of("error", e.getMessage()));
}
```
- Bármilyen nem kezelt `RuntimeException` (NPE, JPA hiba, stb.) üzenete közvetlenül megy a kliensnek
- Ez szivárogtathat: DB oszlopneveket, query részleteket, osztályneveket, stack trace-eket
- Ráadásul HTTP 400-at ad vissza 500 helyett (szerver hiba, nem kliens hiba)

**Javítás:** Generikus hibaüzenet ("Internal server error") + HTTP 500 + szerver-oldali logolás.

---

### #6 — MAGAS — Production Docker Compose kifelé nyitja a PostgreSQL portot

| Mező | Érték |
|------|-------|
| **Súlyosság** | MAGAS |
| **Kategória** | Deployment — Hálózati biztonság |
| **Fájl** | `docker-compose.production.yml` (14-15. sor) |
| **Állapot** | 🔴 Nyitott |

**Leírás:**  
```yaml
ports:
  - "5432:5432"
```
A PostgreSQL adatbázis közvetlenül elérhető a host hálózatról production-ben. Ez lehetővé teszi közvetlen adatbázis-hozzáférési kísérleteket.

**Javítás:** A `ports` szekció eltávolítása, csak a belső Docker hálózaton keresztül legyen elérhető.

---

### #7 — KÖZEPES — DTO-kon nincs `@Size(max=)` validáció

| Mező | Érték |
|------|-------|
| **Súlyosság** | KÖZEPES |
| **Kategória** | Biztonság — Input validáció |
| **Fájlok** | `MedicationDTO.java`, `AppointmentDTO.java`, `MedLogDTO.java` |
| **Állapot** | 🟡 Nyitott |

**Leírás:**  
A DTO-k rendelkeznek `@NotBlank` validációval, de nincs `@Size(max=...)` korlátozás a string mezőkön. Egy támadó multi-megabyte-os stringeket küldhet mezőnként, ami kombinálva a "replace all" mentési mintával DoS-hoz vezethet.

---

### #8 — KÖZEPES — Nincs token refresh mechanizmus

| Mező | Érték |
|------|-------|
| **Súlyosság** | KÖZEPES |
| **Kategória** | Biztonság / UX |
| **Fájl** | `JwtTokenProvider.java`, `application.yml` |
| **Állapot** | 🟡 Nyitott |

**Leírás:**  
JWT tokenek fix 24 órás lejárattal rendelkeznek, nincs refresh token flow. Lejárat után a felhasználónak (célcsoport: idős emberek) teljesen újra kell autentikálnia magát.

---

### #9 — KÖZEPES — Service Worker verzió mismatch

| Mező | Érték |
|------|-------|
| **Súlyosság** | KÖZEPES |
| **Kategória** | Kódminőség |
| **Fájlok** | `sw.js` (v2.1.33) vs `app.js` (v2.1.32) vs `index.html` (v2.1.32) |
| **Állapot** | 🟡 Nyitott |

**Leírás:**  
A Service Worker verziója (`v2.1.33`) eltér az app verziójától (`v2.1.32`). Ez stale cache problémákat vagy felesleges cache invalidációt okozhat.

---

### #10 — KÖZEPES — `entrypoint.sh` sed injection

| Mező | Érték |
|------|-------|
| **Súlyosság** | KÖZEPES |
| **Kategória** | Deployment |
| **Fájl** | `nginx/entrypoint.sh` (14. sor) |
| **Állapot** | 🟡 Nyitott |

**Leírás:**  
```bash
sed -i "s/__SERVER_NAME__/$SERVER_NAME/g" "$NGINX_CONFIG_RENDERED"
```
Ha `$SERVER_NAME` tartalmaz sed speciális karaktereket (`/`, `&`, `\`), a substitúció hibás nginx konfigurációt eredményezhet.

---

### #11 — KÖZEPES — Actuator/Prometheus publikusan elérhető

| Mező | Érték |
|------|-------|
| **Súlyosság** | KÖZEPES |
| **Kategória** | Biztonság |
| **Fájl** | `SecurityConfig.java` (42. sor) |
| **Állapot** | 🟡 Nyitott |

**Leírás:**  
A Prometheus endpoint `permitAll()` a Spring Security szintjén. Bár az Nginx IP-alapon korlátozza, a 8080-as port közvetlen elérésekor (mindkét compose fájlban publikálva) megkerülhető az Nginx.

---

## Már Ismert, Nem Fixált Problémák

### #12 — MAGAS — Nincs pagination

| Mező | Érték |
|------|-------|
| **Kategória** | Teljesítmény |
| **Fájlok** | `MedicationService.java`, `MedLogService.java`, `AppointmentService.java` |
| **Eredeti audit** | §3.2 |

Minden GET endpoint az összes rekordot visszaadja felhasználónként, pagination nélkül.

---

### #13 — MAGAS — ~0% backend teszt lefedettség

| Mező | Érték |
|------|-------|
| **Kategória** | Tesztelés |
| **Eredeti audit** | §4.1 |

Egyetlen `contextLoads()` teszt létezik. Nincsenek service, controller, security tesztek.

---

### #14 — MAGAS — Minimális frontend teszt lefedettség

| Mező | Érték |
|------|-------|
| **Kategória** | Tesztelés |
| **Eredeti audit** | §4.2 |

4 alap teszt az `ApiService`-en. Az 1714 soros `app.js`-nek nulla tesztje van. Nincs E2E teszt.

---

### #15 — KÖZEPES — Dátumok VARCHAR-ként tárolva

| Mező | Érték |
|------|-------|
| **Kategória** | Adatintegritás |
| **Fájlok** | `MedLog.java`, `Appointment.java` |
| **Eredeti audit** | §5.2 |

`date` és `time` mezők `String`/`VARCHAR` típusúak `DATE`/`TIME` helyett.

---

### #16 — KÖZEPES — `MedLog.medId` nincs foreign key-jel kötve

| Mező | Érték |
|------|-------|
| **Kategória** | Adatintegritás |
| **Fájl** | `MedLog.java` |
| **Eredeti audit** | §5.3 |

Gyógyszer törléskor árva log bejegyzések maradnak.

---

### #17 — KÖZEPES — Nincs DB backup stratégia

| Mező | Érték |
|------|-------|
| **Kategória** | Deployment |
| **Eredeti audit** | §5.4 |

Nincs automatikus backup (pg_dump), nincs WAL archiving, nincs restore teszt.

---

### #18 — KÖZEPES — Nincs CI/CD pipeline

| Mező | Érték |
|------|-------|
| **Kategória** | Deployment |
| **Eredeti audit** | §6 |

Nincs GitHub Actions vagy más automatizált build/test/deploy workflow.

---

### #19 — KÖZEPES — Frontend monolitikus struktúra

| Mező | Érték |
|------|-------|
| **Kategória** | Kódminőség |
| **Fájl** | `app.js` (1714 sor) |
| **Eredeti audit** | §7.2 |

Egyetlen fájl, nincs modularizáció, nincs build process.

---

### #20 — KÖZEPES — "Replace all" save pattern

| Mező | Érték |
|------|-------|
| **Kategória** | Kódminőség / Teljesítmény |
| **Eredeti audit** | §7.1 |

Minden POST törli az összes meglévőt, majd újra insertálja a teljes listát. Nincs egyedi CRUD.

---

### #21 — ALACSONY — Admin email hardkódolva a frontend-ben

| Mező | Érték |
|------|-------|
| **Fájl** | `app.js` (6. sor) |
| **Eredeti audit** | §2.3 |

---

### #22 — ALACSONY — Swagger UI elérhető production-ben

| Mező | Érték |
|------|-------|
| **Fájl** | `SecurityConfig.java` |
| **Eredeti audit** | §7.3 |

---

### #23 — ALACSONY — `package.json` rossz projektnév

| Mező | Érték |
|------|-------|
| **Fájl** | `package.json` (2. sor) |

`"name": "oepncode-test1"` — nem a valós projektnév.

---

### #24 — ALACSONY — Legacy Supabase OAuth kód + duplikált schema.sql

| Mező | Érték |
|------|-------|
| **Fájlok** | `app.js` (1707-1710. sor), `db/schema.sql` |

Régi Supabase redirect kezelő kód és a Flyway migráció mellett felesleges `schema.sql`.

---

## Javítási Terv

### Tier 1 — Deploy előtt KÖTELEZŐ (1-2 nap)

| # | Probléma | Becsült effort |
|---|----------|----------------|
| 1 | Google OAuth token verifikáció | 2-3 óra |
| 2 | Rate limit filter sorrend | 15 perc |
| 3 | Rate limiter memóriaszivárgás | 1 óra |
| 4 | Login user enumeration fix | 15 perc |
| 5 | RuntimeException handler fix | 30 perc |
| 6 | PostgreSQL port eltávolítása production-ből | 5 perc |

### Tier 2 — Deploy után 1 héten belül

| # | Probléma | Becsült effort |
|---|----------|----------------|
| 7 | DTO `@Size` validáció | 30 perc |
| 8 | Actuator endpoint-ok védelme | 30 perc |
| 12 | Pagination bevezetése | 1 nap |
| 13 | Backend tesztek írása | 3-5 nap |

### Tier 3 — 1 hónapon belül

| # | Probléma | Becsült effort |
|---|----------|----------------|
| 9 | Service Worker verzió szinkronizálás | 15 perc |
| 10 | entrypoint.sh sed injection fix | 15 perc |
| 15-16 | Dátum migrálás + FK kialakítás | 1 nap |
| 17 | DB backup stratégia | 1 nap |
| 18 | CI/CD pipeline | 1 nap |
| 19 | Frontend modularizáció | 3-5 nap |

---

*Ez a dokumentum a teljes codebase manuális átvizsgálásán alapul. A korábbi audit (2026-02-22) eredményeit is figyelembe veszi, kiegészítve az akkor nem azonosított problémákkal.*
