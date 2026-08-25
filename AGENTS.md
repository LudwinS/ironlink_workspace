# IronLink — Contexto de Proyecto, Reglas y Guía de Desarrollo

Este documento replica y consolida todo el contexto, decisiones de arquitectura, estado de backlog y directrices de trabajo de **IronLink** para los asistentes de IA (Antigravity / Codex / Claude).

---

## 1. Información General del Proyecto y Entorno

- **Nombre del Proyecto:** IronLink (*"Conecta • Comunica • Colabora"*)
- **Materia / Ciclo:** Ingeniería de Software 2 — Ciclo 2-2026 (Universidad)
- **Ruta del Repositorio:** `/Users/ludwin/Documents/Universidad/2026-2/ingenieria-de-software/4_Proyectos_y_Examenes/ironlink_workspace`
- **Ruta de Tareas y Backlog:** `/Users/ludwin/Documents/Universidad/2026-2/ingenieria-de-software/2_Tareas`
  - Product Backlog: `Product_Backlog_Nueva_Plantilla_IRONLINK.xlsx`
  - Control Sprint 2: `Control_Product_Backlog_Sprint_2_IRONLINK.xlsx`
  - Capacidad / Tiempo de ayer: `EL_TIEMPO_DE_AYER_IRONLINK.xlsx`

---

## 2. Stack Tecnológico y Arquitectura

### Backend (`backend/`)
- **Lenguaje / Runtime:** Rust (edition 2021) + Tokio (async runtime).
- **Framework Web:** Axum (`axum`, `tower`, `tower-http`).
- **Base de Datos & ORM/Query:** PostgreSQL con SQLx (consultas parametrizadas y migraciones).
- **Autenticación & Seguridad:**
  - Hashing de contraseñas con **Argon2id** y salt aleatorio.
  - JWT de corta duración + Refresh Tokens con revocación.
  - Modelo RBAC unificado (`USER` / `MEMBER` / `ADMIN`).
- **Comunicaciones:** API REST + WebSockets para eventos de chat y presencia en tiempo real.

### Frontend (`frontend/`)
- **Framework:** Flutter (Multiplataforma: macOS Desktop, Web, Windows).
- **Gestión de Estado:** Riverpod.
- **Enrutamiento:** GoRouter.
- **Cliente HTTP:** Dio con interceptores de autenticación y renovación de tokens.
- **Almacenamiento Seguro:** `flutter_secure_storage` para tokens y credenciales.
- **Assets & Branding:** `frontend/assets/logo.png`.

---

## 3. Estado del Sprint 2 y Compromisos

### Sprint Goal
> *"Habilitar una experiencia básica de colaboración dentro de los nodos de IronLink, permitiendo que los miembros se identifiquen mediante su perfil, se comuniquen a través de un chat persistente y organicen su trabajo mediante subgrupos y reuniones programadas."*

### Historias Comprometidas (Sprint 2 - 64 horas totales)
| ID | Historia / Funcionalidad | Esfuerzo Restante | Estado |
|---|---|---|---|
| **IRL-WKS-US-03** | Chat persistente en nodos/canales | 12 h | `In Progress` |
| **IRL-WKS-US-02** | Creación y gestión de subgrupos | 20 h | `Ready` |
| **IRL-WKS-US-04** | Programación de reuniones de nodo | 20 h | `Ready` |
| **IRL-IAM-US-05** | Perfil de usuario y personalización | 12 h | `Ready` |

### Estructura de Tablero Kanban
- Columnas requeridas (4): **`Por hacer`** | **`En progreso`** | **`Revisión/QA`** | **`Finalizado`**.

---

## 4. Reglas de Desarrollo y Buenas Prácticas

1. **Verificación y Auditoría Previa (Read-First):**
   - Siempre revisar código, rutas, migraciones y pruebas existentes antes de proponer o aplicar cambios.
   - No asumir que un feature está "100% terminado" solo por lo que diga un README sin inspeccionar la implementación real.

2. **Refactorización Vertical e Incremental:**
   - Modificar únicamente el flujo vertical afectado: tests primero $\rightarrow$ mover código sin cambiar comportamiento $\rightarrow$ verificar $\rightarrow$ commit de refactor $\rightarrow$ commit de funcionalidad.
   - No sobreescribir `001_sprint1_complete.sql`; añadir nuevas migraciones secuenciales `002_*.sql`.
   - Mantener desacoplados los módulos (`chat` separado de `nodos`).

3. **Criterio de Seguridad Riguroso:**
   - No clasificar JWT + HTTPS + almacenamiento seguro como "E2EE" (End-to-End Encryption). El cifrado E2EE requiere protocolo de intercambio de claves cliente-cliente sin acceso al texto plano en el servidor.
   - Manejo seguro de errores en DB: *fail-closed* ante fallos en verificación de permisos o roles.

4. **Solución a Problemas Conocidos de macOS / Flutter:**
   - **Error de CodeSign (`resource fork, Finder information...`):**
     Ejecutar limpieza de atributos extendidos de macOS:
     `xattr -cr build/macos` y en los directorios de assets/código si persiste.
   - Preservar archivos de metadatos locales: `frontend/.metadata`, `frontend/pubspec.lock`, `frontend/macos/`.

5. **Rol del Asistente (Tutor & Pair Programmer):**
   - Explicar entradas, validaciones, lógica de autorización, persistencia y manejo de errores.
   - El código generado debe ser entendible y defendible por el estudiante en sus revisiones académicas.
