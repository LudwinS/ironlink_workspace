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

## Arquitectura de Tokens de Acceso y Sesión (JWT)

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


