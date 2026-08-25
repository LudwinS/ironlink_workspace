# 📑 Reporte Integral de Historias de Usuario — Sprint 1 & Sprint 2 (IronLink Enterprise)

Este documento consolida el progreso, estado técnico, arquitectura de seguridad y base de datos relacional correspondiente al **Sprint 1** y al **Sprint 2** del sistema **IronLink**, desarrollado por el equipo **InnovaSoft** (7 integrantes).

---

## 👥 Equipo de Desarrollo e Ingeniería (InnovaSoft — 7 Integrantes)

1. **Ludwin Saúl Vásquez Romero** — Scrum Master / Backend & Architecture Lead
2. **Luis Alexander Rivera Alvarez** — QA Lead / Database & Security Dev
3. **Alberto José Velázquez Paz** — Frontend Lead / Desktop UI & QA Tester
4. **Luis Ángel Zúñiga Menjívar** — Backend Dev / API Security & Conformance
5. **Ricardo Alberto Mendiola Hernández** — Dev / Chat Persistente & Perfil Lead
6. **Víctor Arnoldo Iglesias Sandoval** — Dev / Reuniones & Servicios Síncronos
7. **José Luis Fuentes Ochoa** — Dev / Subgrupos & Organización de Nodos

---

## 📋 Cuadro General de Progreso de Historias de Usuario

| ID Historia | Épica / Característica | Estado Frontend | Estado Backend | Estatus General | Sprint |
|---|---|---|---|---|---|
| **IRL-IAM-US-01** | Registro seguro de usuarios con entropía y Argon2id | **100% Completado** | **100% Completado** | **Terminado** | Sprint 1 |
| **IRL-IAM-US-02** | Verificación por doble canal OTP (6 dígitos) y Magic Link | **100% Completado** | **100% Completado** | **Terminado** | Sprint 1 |
| **IRL-IAM-US-04** | Inicio de sesión con correo, contraseña y tokens JWT | **100% Completado** | **100% Completado** | **Terminado** | Sprint 1 |
| **IRL-IAM-US-06** | Gestión de roles y control de acceso basado en roles (RBAC) | **100% Completado** | **100% Completado** | **Terminado** | Sprint 1 |
| **IRL-WKS-US-01** | Creación y administración de Nodos (Salas) con tokens únicos | **100% Completado** | **100% Completado** | **Terminado** | Sprint 1 |
| **IRL-WKS-US-03** | Chat persistente en canales de Nodo con avatar y roles | **100% Completado** | **100% Completado** | **Terminado** | **Sprint 2** |
| **IRL-WKS-US-02** | Creación de Subgrupos públicos/privados y membresías dinámicas | **100% Completado** | **100% Completado** | **Terminado** | **Sprint 2** |
| **IRL-WKS-US-04** | Programación de reuniones síncronas con Google Meet y UTC | **100% Completado** | **100% Completado** | **Terminado** | **Sprint 2** |
| **IRL-IAM-US-05** | Perfil de usuario, presencia en tiempo real y cambio seguro de clave | **100% Completado** | **100% Completado** | **Terminado** | **Sprint 2** |

---

## 🛡️ Arquitectura de Seguridad, Criptografía y Tokens JWT

### 1. Tokens de Acceso y Refresco (Doble Token JWT)
*   **Access Token**: Emitido por el backend en `/login` tras validar credenciales con Argon2id. Contiene el ID del usuario (`sub`), rol (`role`) y expiración de 15 minutos.
*   **Refresh Token**: Token opaco persistido en PostgreSQL con vigencia de 7 días. Permite renovación desatendida mediante rotación criptográfica.
*   **Transmisión**: El cliente de escritorio inyecta automáticamente la cabecera `Authorization: Bearer <token>` en cada consulta HTTP protegida.

### 2. Hashing de Contraseñas con Argon2id
*   Todas las credenciales se hashean utilizando **Argon2id** con salt criptográfico generado por hardware (`rand::rngs::OsRng`), previniendo ataques de canal lateral y tablas rainbow.

---

## 🗄️ Esquema de Base de Datos Relacional (PostgreSQL)

### Migración 001 (`001_sprint1_complete.sql`)
*   `users`: ID, email, password_hash, full_name, telefono, rol, is_active, status, token_verificacion, token_expiracion, avatar_color, bio, status_text.
*   `nodos`: ID, nombre, descripcion, token_acceso, creado_por, created_at.
*   `nodo_miembros`: ID, id_nodo, id_usuario, rol, joined_at.

### Migración 002 (`002_sprint2_colaboracion.sql`)
*   `mensajes`: ID, id_nodo, id_usuario, contenido, created_at (TIMESTAMPTZ UTC).
*   `subgrupos`: ID, id_nodo, nombre, descripcion, es_privado, creado_por, created_at.
*   `subgrupo_miembros`: ID, id_subgrupo, id_usuario, rol, joined_at.
*   `reuniones`: ID, id_nodo, titulo, descripcion, fecha_reunion, duracion_minutos, meet_url, creada_por, created_at.

---

## 🧪 Resumen de Calidad y Pruebas (QA Testing)

*   **Total de Casos de Prueba Ejecutados en Sprint 2**: 23 Casos Diseñados y Ejecutados.
*   **Tasa de Aprobación**: **100% Pasa** (0 errores bloqueantes).
*   **Defectos Detectados y Resueltos**: 5 Bugs cerrados (BUG-S2-001 al BUG-S2-005).
*   **Auditoría de DoR y DoD**: 100% de cumplimiento verificado en Trello y matrices de trazabilidad.
*   **Plataforma de Ejecución**: macOS darwin-arm64 (Apple Silicon) & Windows x64.
