---
name: connect-ong-tech-guidelines
description: Mandatory engineering standards for every new Connect ONG feature (stack is fixed by the school)
metadata: 
  node_type: memory
  type: reference
  originSessionId: 5cad0449-bb13-42c4-b449-94fc3000ffdf
---

Stack is fixed (school requirement — do not switch languages): **Flutter/Dart** (frontend), **Java/Spring Boot** (backend), **MySQL** (DB), Git/GitHub, Postman for testing.

Every new feature must follow these standards (from the user's directive):

**Backend:** layered architecture (Controller → Service → Repository → DTO → Model); single responsibility; **DTOs for input AND output** (do not expose entities directly — the current controllers return entities/maps, which should migrate to DTOs); centralized validation; **global exception handling** (@RestControllerAdvice); automated tests; **OpenAPI/Swagger** documentation.

**Frontend:** consistent state management; reusable components; a **design system**; responsiveness; accessibility; visual feedback (loading/error/success states).

**⚡ PERFORMANCE (regra descoberta em 2026-07-14, vale p/ TODA feature nova):** o backend roda no Render (Oregon, EUA) e o MySQL é o da escola (Brasil) → **cada ida ao banco custa ~600ms** (o SQL em si roda em 0,025s; o custo é a viagem). **Tempo de um endpoint ≈ (nº de consultas) × 600ms.** Portanto: **NUNCA fazer consulta dentro de laço/`map`** (N+1) e preferir **1 consulta agregada**. ⚠️ **`@ManyToOne` é EAGER por padrão no JPA** — toda listagem com `findAll()` numa entidade com `@ManyToOne` dispara 1 consulta por relação por item. **Fix padrão: `LEFT JOIN FETCH`** numa `@Query` (LEFT p/ não sumir com órfãos; preservar a ORDENAÇÃO do método substituído). Isso já rendeu: `/publico/estatisticas` 4,8s→0,50s, `/necessidades` 3,9s→0,77s, `/ongs` 6,9s→1,85s. **Ao otimizar, SEMPRE compare a resposta antes/depois** (a suíte tem 165 testes em H2 na memória — `./mvnw test` é seguro, não toca o banco da escola). Ver [[connect-ong-web-doador-plano]].

**Database:** normalization; referential integrity; indexes; **migrations** (currently uses Hibernate ddl-auto=update — should move to versioned migrations e.g. Flyway); auditing.

**Governing rule:** no isolated features. Each feature must solve a real problem, generate value, be scalable, improve UX, and be documented. **Quality over quantity.** See [[connect-ong-vision]] and [[connect-ong-architecture]] for current state vs target.
