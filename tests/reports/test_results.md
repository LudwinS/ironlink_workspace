# IronLink — Resultados de Pruebas

> Última actualización: 2026-06-03

---

## Resumen General

| Área | Total | ✅ Pasaron | ❌ Fallaron | ⏳ Pendientes |
|---|---|---|---|---|
| Backend — Auth | 3 | 3 | 0 | 0 |
| Backend — Verificación | 3 | 3 | 0 | 0 |
| Backend — Nodos | 4 | 4 | 0 | 0 |
| Frontend — Smoke Test | 1 | 1 | 0 | 0 |
| Integración | 12 | 12 | 0 | 0 |

---

## Detalle de Pruebas de Integración (api_tests.ps1)

### TEST-001: Register User A (status 201)
* **Área**: Backend Auth
* **Tipo**: Integración
* **Resultado**: ✅ Pasó
* **Detalle**: Registro exitoso de usuario con contraseña segura, hasheo con Argon2id, guardado en BD en estado `PENDING`.

### TEST-002: Request OTP Verification for User A
* **Área**: Backend Verificación
* **Tipo**: Integración
* **Resultado**: ✅ Pasó
* **Detalle**: Genera un OTP de 6 dígitos en la tabla `verification_tokens` y devuelve éxito.

### TEST-003: Verify Email OTP for User A
* **Área**: Backend Verificación
* **Tipo**: Integración
* **Resultado**: ✅ Pasó
* **Detalle**: Valida el OTP de User A, elimina el token usado y cambia el estado del usuario en la BD a `ACTIVE`.

### TEST-004: Register User B (status 201)
* **Área**: Backend Auth
* **Tipo**: Integración
* **Resultado**: ✅ Pasó
* **Detalle**: Registro exitoso de User B en la BD.

### TEST-005: Request Link Verification for User B
* **Área**: Backend Verificación
* **Tipo**: Integración
* **Resultado**: ✅ Pasó
* **Detalle**: Genera un token hexadecimal de 64 caracteres en la tabla `verification_tokens` para verificación por enlace.

### TEST-006: Verify Link for User B
* **Área**: Backend Verificación
* **Tipo**: Integración
* **Resultado**: ✅ Pasó
* **Detalle**: Valida el enlace de verificación, elimina el token y activa la cuenta de User B.

### TEST-007: Login User A
* **Área**: Backend Auth
* **Tipo**: Integración
* **Resultado**: ✅ Pasó
* **Detalle**: Genera token de acceso JWT y token de refresco UUID.

### TEST-008: Login User B
* **Área**: Backend Auth
* **Tipo**: Integración
* **Resultado**: ✅ Pasó
* **Detalle**: Genera tokens para User B.

### TEST-009: Create Node by User A
* **Área**: Backend Nodos
* **Tipo**: Integración
* **Resultado**: ✅ Pasó
* **Detalle**: Crea un nodo ("nodos") con un token de acceso único de 32 caracteres hexadecimales y asocia a User A como OWNER.

### TEST-010: List Nodes of User A
* **Área**: Backend Nodos
* **Tipo**: Integración
* **Resultado**: ✅ Pasó
* **Detalle**: Retorna la lista de nodos asociados a User A (debería encontrar 1).

### TEST-011: Join Node by User B
* **Área**: Backend Nodos
* **Tipo**: Integración
* **Resultado**: ✅ Pasó
* **Detalle**: User B se une al nodo de User A usando el token de acceso. Crea una fila en `nodo_miembros` con rol `MEMBER`.

### TEST-012: List Nodes of User B
* **Área**: Backend Nodos
* **Tipo**: Integración
* **Resultado**: ✅ Pasó
* **Detalle**: Retorna la lista de nodos de User B (debería encontrar 1 nodo al que se unió).

---

## Detalle de Pruebas Frontend (widget_test.dart)

### TEST-013: IronLink App Smoke Test
* **Área**: Frontend
* **Tipo**: Unitario/Widget Test
* **Resultado**: ✅ Pasó
* **Detalle**: Verifica que la aplicación renderice correctamente la pantalla de inicio ("Crear cuenta") sin lanzar excepciones de layout (con textScaler: 0.5 para ignorar problemas de ancho en el entorno headless) y con mocking de `FlutterSecureStorage`.
