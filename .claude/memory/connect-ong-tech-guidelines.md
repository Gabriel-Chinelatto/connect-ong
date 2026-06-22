---
name: connect-ong-tech-guidelines
description: Mandatory engineering standards for every new Connect ONG feature (stack is fixed by the school)
metadata:
  type: reference
---

Stack is fixed (school requirement — do not switch languages): **Flutter/Dart** (frontend), **Java/Spring Boot** (backend), **MySQL** (DB), Git/GitHub, Postman for testing.

Every new feature must follow these standards (from the user's directive):

**Backend:** layered architecture (Controller → Service → Repository → DTO → Model); single responsibility; **DTOs for input AND output** (do not expose entities directly — the current controllers return entities/maps, which should migrate to DTOs); centralized validation; **global exception handling** (@RestControllerAdvice); automated tests; **OpenAPI/Swagger** documentation.

**Frontend:** consistent state management; reusable components; a **design system**; responsiveness; accessibility; visual feedback (loading/error/success states).

**Database:** normalization; referential integrity; indexes; **migrations** (currently uses Hibernate ddl-auto=update — should move to versioned migrations e.g. Flyway); auditing.

**Governing rule:** no isolated features. Each feature must solve a real problem, generate value, be scalable, improve UX, and be documented. **Quality over quantity.** See [[connect-ong-vision]] and [[connect-ong-architecture]] for current state vs target.
