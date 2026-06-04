# 📑 Reporte de Progreso de Historias de Usuario — Sprint 1 (IronLink)

Este documento resume el progreso y estado actual de las Historias de Usuario planificadas para el **Sprint 1** de **IronLink**, detallando el funcionamiento de la arquitectura de seguridad y tokens de acceso (JWT).

---

## 📋 Cuadro de Progreso de Historias de Usuario

| ID de Historia | Tarea / Característica | Estado Frontend | Estado Backend | Estatus General |
|---|---|---|---|---|
| **IRL-IAM-US-01** | Registro de usuarios con validaciones de contraseña segura. | **100% Completado** | **100% Completado** | **Terminado** |
| **IRL-IAM-US-02** | Verificación de correo por código OTP y Enlace de activación. | **100% Completado** | **100% Completado** | **Terminado** |
| **IRL-IAM-US-04** | Inicio de sesión con correo, contraseña y JWT. | **100% Completado** | **100% Completado** | **Terminado** |
| **IRL-IAM-US-06** | Gestión de roles y restricciones de acceso (RBAC). | **100% Completado** | **100% Completado** | **Terminado** |
| **IRL-WKS-US-01** | Creación y gestión de Nodos (Workspaces) con tokens de invitación. | **100% Completado** | **100% Completado** | **Terminado** |

---

## 🔑 Arquitectura de Tokens de Acceso y Sesión (JWT)

Para cumplir con las políticas de seguridad y comunicación de extremo a extremo, se ha implementado un esquema de **Doble Token (Access + Refresh Token)**:

### 1. Access Token (Token de Acceso)
*   **Tecnología**: JSON Web Token (JWT).
*   **Generación**: Emitido por el backend en `/login` tras validar las credenciales de un usuario `ACTIVE`.
*   **Contenido (Claims)**: Contiene el ID del usuario (`sub`), su rol (`role`) y la fecha de expiración (`exp`).
*   **Vigencia**: 15 minutos (para mitigar el riesgo si el token es interceptado).
*   **Transmisión**: El frontend (`ApiClient` en Dio) lo inyecta automáticamente en la cabecera `Authorization: Bearer <token>` en cada consulta a rutas protegidas.

### 2. Refresh Token (Token de Refresco)
*   **Tecnología**: Identificador único aleatorio (UUIDv4).
*   **Almacenamiento**: Guardado de forma segura en la base de datos (tabla `refresh_tokens`) y retornado al cliente.
*   **Vigencia**: 7 días.
*   **Objetivo**: Permitir al frontend solicitar un nuevo Access Token cuando este expire sin obligar al usuario a introducir sus credenciales nuevamente.

### 3. Persistencia en el Frontend
*   Los tokens y datos del usuario se almacenan de manera encriptada utilizando **DPAPI nativo de Windows** y **Android EncryptedSharedPreferences** a través de la biblioteca `SecureVault` (que usa `FlutterSecureStorage`).
*   **Arreglo del Interceptor (Importante)**: Se corrigió un bug en `api_client.dart` donde el interceptor de peticiones no se estaba agregando en ciertas circunstancias (debido a la presencia de interceptores predeterminados de Flutter en la lista `Dio`). Ahora se inicializa de forma robusta con un flag booleano, asegurando la transmisión continua del token.

---

## 🎯 Detalle de Historias de Usuario

### 1. IRL-IAM-US-01: Registro Seguro
*   **Frontend**: Formulario con indicador visual de seguridad de contraseña de 5 niveles (mínimo 8 caracteres, mayúsculas, minúsculas, números y caracteres especiales) con validaciones inline en tiempo real.
*   **Backend**: Hasheo de contraseña con **Argon2id** de forma segura y validación de correos y teléfonos duplicados. Asignación automática de rol `ADMIN` para correos con el nombre `"ludwin"`.

### 2. IRL-IAM-US-02: Verificación de Cuenta
*   **Frontend**: Pantalla con fila de 6 campos de texto de auto-enfoque para código OTP y opción de reenvío con temporizador de 60 segundos. Pantalla de éxito en paso `③ LISTO`.
*   **Backend**: Envío de código OTP de 6 dígitos o enlace seguro de 64 caracteres por correo real (usando el servidor SMTP de Gmail autenticado con App Password). Activación en base de datos (`estado = 'ACTIVE'`) y limpieza automática de tokens.

### 3. IRL-IAM-US-04: Inicio de Sesión y Seguridad
*   **Backend**: Bloqueo de cuenta automático tras 5 intentos fallidos consecutivos durante 15 minutos (columna `bloqueado_hasta` en la base de datos). 
*   **Frontend**: Almacenamiento seguro del token de acceso tras el login y navegación condicional automática (`GoRouter`) en base al estado de sesión en `SecureVault`.

### 4. IRL-IAM-US-06: Control de Roles (RBAC)
*   **Base de Datos**: Roles tipados como ENUM (`'ADMIN'`, `'MODERATOR'`, `'MEMBER'`). La cuenta `ludwinsaulromero@gmail.com` está configurada como `ADMIN` con acceso total.
*   **Backend**: Middleware `jwt_auth` para validar firmas de tokens y middleware `require_admin` para restringir accesos administrativos (como el cambio de roles en `/admin/users/:id/role`).
*   **Frontend**: Ocultamiento de la pestaña de Configuración en el menú lateral para usuarios sin rol `ADMIN`.

### 5. IRL-WKS-US-01: Nodos y Moderación (Estilo Discord)
*   **Nomenclatura**: Se eliminó toda referencia a "aulas/salas/UGB" y se adaptó la terminología técnica a **Nodos** e **IronLink**.
*   **Creación**: Cualquier usuario puede crear un nodo desde la barra lateral o botón flotante. El creador se registra automáticamente como miembro con rol `'OWNER'`.
*   **Invitación**: Generación de tokens únicos hexadecimales de 32 caracteres para compartir. Otros usuarios pueden unirse al nodo introduciendo este token en la interfaz de "Unirse a nodo".

---

## 🐛 Historial de Errores Encontrados y Solucionados (Bugs)

Durante el desarrollo del Sprint 1, se detectaron, documentaron y corrigieron los siguientes errores:

### 1. Error de Bloqueo de Login al no marcar "Recuérdame"
*   **Problema**: Cuando el usuario intentaba iniciar sesión con las credenciales correctas pero **sin** marcar la casilla de "Recordarme", el login fallaba y lo regresaba inmediatamente a la pantalla de `/login`.
*   **Causa**: La función `SecureVault.hasSession()` comprobaba si la clave `remember_me` era `'true'` para validar la sesión. Al no marcar la casilla, `remember_me` se guardaba como `'false'`. El enrutador ([app_router.dart](file:///C:/Users/Ludwin/ironlink_workspace/frontend/lib/core/router/app_router.dart)) ejecutaba su redirección de seguridad, detectaba `hasSession() == false` y forzaba el retorno a `/login` a pesar de que el token JWT era válido y el inicio de sesión del backend había sido exitoso.
*   **Solución**: Se separó la comprobación de sesión activa (que ahora solo verifica la existencia del token JWT en [secure_vault.dart](file:///C:/Users/Ludwin/ironlink_workspace/frontend/lib/core/security/secure_vault.dart)) de la comprobación de persistencia al arrancar la app. Si al arrancar la app `remember_me` es `'false'`, los tokens se limpian y se exige login; de lo contrario, se mantiene la navegación fluida.

### 2. Error de Conteo de Participantes en Nodos
*   **Problema**: Cuando un usuario creaba un nodo o cuando otro usuario se unía a él mediante el token de acceso de 32 caracteres, el contador de miembros en la interfaz no se actualizaba (mostraba siempre `0` o datos estáticos).
*   **Causa**: El backend no estaba calculando la suma de registros en la tabla intermedia `nodo_miembros` durante las consultas SQL de listado, creación y unión de nodos.
*   **Solución**: Se incorporó una subconsulta `miembros_count` en las consultas de base de datos del backend ([service.rs](file:///C:/Users/Ludwin/ironlink_workspace/backend/src/nodos/service.rs)) para que devuelva dinámicamente la cantidad real de participantes vinculados a cada nodo.

### 3. Confusión de Token de Verificación Requerido
*   **Problema**: Al intentar crear un nodo o unirse a uno, el sistema mostraba un error que indicaba "Token de autenticación requerido" o errores de validación de token.
*   **Causa**: Había una colisión y confusión de conceptos entre el token de verificación de cuenta de correo (OTP de 6 dígitos / enlace de correo) y el token JWT de acceso del usuario para peticiones HTTP autenticadas.
*   **Solución**: Se reestructuraron los endpoints del backend para que el middleware de autenticación (`jwt_auth`) solo aplique a rutas protegidas (`/nodos`), mientras que las rutas de verificación (`/verify-email`, `/verify-link`) se mantengan completamente públicas. Además, se pulió el interceptor HTTP de Dio en el frontend para asegurar el envío consistente de la cabecera `Authorization: Bearer <token>`.

### 4. Restos de Nomenclatura Antigua ("Aulas" y "UGB")
*   **Problema**: Varias pantallas del frontend y variables mostraban referencias a "aulas virtuales", "salas", "calendarios" e identificadores institucionales de la universidad UGB.
*   **Causa**: Copias y plantillas remanentes del sistema universitario previo.
*   **Solución**: Se realizó una limpieza de código integral en los archivos de la interfaz ([login_screen.dart](file:///C:/Users/Ludwin/ironlink_workspace/frontend/lib/features/iam/presentation/login_screen.dart), [register_screen.dart](file:///C:/Users/Ludwin/ironlink_workspace/frontend/lib/features/iam/presentation/register_screen.dart) y [dashboard_screen.dart](file:///C:/Users/Ludwin/ironlink_workspace/frontend/lib/features/nodos/presentation/dashboard_screen.dart)) renombrando todos los elementos a "Nodos" e "IronLink", eliminando por completo la sección de calendario institucional y desvinculando cualquier logotipo de la UGB.

### 5. Fallo de Interceptor de Token JWT en Dio
*   **Problema**: Aleatoriamente las peticiones del frontend fallaban con código 401 Unauthorized en el backend debido a que no se inyectaba el token de acceso, obligando al usuario a re-autenticarse constantemente.
*   **Causa**: La lista de interceptores del cliente HTTP (Dio) duplicaba instancias o se saltaba la inyección del token si se realizaban múltiples peticiones asíncronas concurrentes.
*   **Solución**: Se modificó la inicialización en `api_client.dart` usando un patrón Singleton estricto con un flag de inicialización que garantiza que el interceptor de autorización se configure una única vez y tenga prioridad absoluta sobre las cabeceras HTTP.

