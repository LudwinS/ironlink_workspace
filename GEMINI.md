# Reglas de Trabajo para IronLink (Antigravity)

Consulta [AGENTS.md](file:///Users/ludwin/Documents/Universidad/2026-2/ingenieria-de-software/4_Proyectos_y_Examenes/ironlink_workspace/AGENTS.md) para el contexto completo de arquitectura y backlog.

### Directrices Rápidas:
- **Stack:** Rust (Axum, Tokio, SQLx, Postgres) en `backend/` y Flutter (Riverpod, GoRouter, Dio) en `frontend/`.
- **Sprint 2:** Mantener el foco en las 4 historias de colaboración (`IRL-WKS-US-03`, `IRL-WKS-US-02`, `IRL-WKS-US-04`, `IRL-IAM-US-05`).
- **Control de calidad:** Verificar código real antes de validar entregables. Realizar cambios incrementales y defensibles.
- **macOS Build Fix:** Usar `xattr -cr` si ocurren errores de CodeSign por atributos extendidos en macOS.
