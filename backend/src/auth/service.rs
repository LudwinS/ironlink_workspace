use serde::{Deserialize, Serialize};
use axum::extract::State;
use axum::http::StatusCode;
use axum::Json;
use std::collections::HashMap;
use uuid::Uuid;
use chrono::{Duration, Utc};
use argon2::{
    password_hash::{rand_core::OsRng, PasswordHasher, PasswordVerifier, PasswordHash, SaltString},
    Argon2
};

use crate::auth::jwt::generate_access_token;
use crate::auth::verification::AppState;

// ─── DTOs ────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub struct RegisterUserDto {
    pub name: String,
    pub email: String,
    pub phone: String,
    pub password: String
}

#[derive(Deserialize)]
pub struct LoginDto {
    pub email: String,
    pub password: String,
}

#[derive(Serialize)]
pub struct ApiResponse {
    pub success: bool,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub field_errors: Option<HashMap<String, String>>,
}

#[derive(Serialize)]
pub struct LoginResponse {
    pub success: bool,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub access_token: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub refresh_token: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub user: Option<LoginUserInfo>,
}

#[derive(Serialize)]
pub struct LoginUserInfo {
    pub id: Uuid,
    pub name: String,
    pub email: String,
    pub role: String,
}

#[derive(Deserialize)]
pub struct ChangeRoleDto {
    pub role: String,
}

// ─── Validación de contraseña ────────────────────────────────────────────

/// Valida la contraseña y retorna un mapa de errores por campo.
/// Si el mapa está vacío, la contraseña cumple todos los criterios.
pub fn validate_password(password: &str) -> HashMap<String, String> {
    let mut errors: Vec<String> = Vec::new();

    if password.chars().count() < 8 {
        errors.push("Debe tener al menos 8 caracteres".to_string());
    }
    if !password.chars().any(|c| c.is_uppercase()) {
        errors.push("Debe contener al menos una mayúscula".to_string());
    }
    if !password.chars().any(|c| c.is_lowercase()) {
        errors.push("Debe contener al menos una minúscula".to_string());
    }
    if !password.chars().any(|c| c.is_numeric()) {
        errors.push("Debe contener al menos un número".to_string());
    }
    if !password.chars().any(|c| "!@#$%^&*()_+-=[]{}|;:',.<>?/".contains(c)) {
        errors.push("Debe contener al menos un carácter especial".to_string());
    }

    let mut field_errors = HashMap::new();
    if !errors.is_empty() {
        field_errors.insert("password".to_string(), errors.join(". "));
    }
    field_errors
}

// ─── POST /register ──────────────────────────────────────────────────────

pub async fn register_user(
    State(state): State<AppState>,
    Json(payload): Json<RegisterUserDto>,
) -> (StatusCode, Json<ApiResponse>) {
    let mut field_errors = HashMap::new();

    // 1. Validar nombre
    let trimmed_name = payload.name.trim();
    if trimmed_name.is_empty() {
        field_errors.insert("name".to_string(), "El nombre no puede estar vacío.".to_string());
    } else if trimmed_name.chars().count() < 2 {
        field_errors.insert("name".to_string(), "El nombre debe tener al menos 2 caracteres.".to_string());
    }

    // 2. Validar email
    let trimmed_email = payload.email.trim();
    if trimmed_email.is_empty() {
        field_errors.insert("email".to_string(), "El correo electrónico es requerido.".to_string());
    } else if !trimmed_email.contains('@') {
        field_errors.insert("email".to_string(), "Formato de correo electrónico inválido.".to_string());
    }

    // 3. Validar teléfono (esperado con prefijo internacional, ej. +50312345678)
    let trimmed_phone = payload.phone.trim();
    if trimmed_phone.is_empty() {
        field_errors.insert("phone".to_string(), "El teléfono es requerido.".to_string());
    } else if !trimmed_phone.starts_with('+') || !trimmed_phone[1..].chars().all(|c| c.is_ascii_digit()) {
        field_errors.insert("phone".to_string(), "El formato del teléfono debe incluir el prefijo internacional (ej: +50312345678).".to_string());
    } else if trimmed_phone.chars().count() < 8 || trimmed_phone.chars().count() > 17 {
        field_errors.insert("phone".to_string(), "Longitud de número de teléfono inválida.".to_string());
    }

    // 4. Validar contraseña con criterios de seguridad
    let password_errors = validate_password(&payload.password);
    if !password_errors.is_empty() {
        if let Some(err) = password_errors.get("password") {
            field_errors.insert("password".to_string(), err.clone());
        }
    }

    if !field_errors.is_empty() {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiResponse {
                success: false,
                message: "Datos de registro inválidos.".to_string(),
                field_errors: Some(field_errors),
            }),
        );
    }

    // 5. Buscar si ya existe el correo o teléfono en la base de datos
    let existing_users = sqlx::query_as::<_, (Uuid, String, String, String)>(
        "SELECT id, email, telefono, estado::TEXT FROM users WHERE email = $1 OR telefono = $2"
    )
    .bind(trimmed_email)
    .bind(trimmed_phone)
    .fetch_all(&state.pool)
    .await;

    match existing_users {
        Ok(users) => {
            let mut conflict_errors = HashMap::new();
            for (id, email, phone, estado) in users {
                if estado == "PENDING" {
                    // Si está PENDING, lo eliminamos para permitir el re-registro libremente
                    if let Err(e) = sqlx::query("DELETE FROM users WHERE id = $1")
                        .bind(id)
                        .execute(&state.pool)
                        .await
                    {
                        eprintln!("Error al eliminar usuario PENDING duplicado: {}", e);
                        return (
                            StatusCode::INTERNAL_SERVER_ERROR,
                            Json(ApiResponse {
                                success: false,
                                message: "Error interno al limpiar el registro anterior incompleto.".to_string(),
                                field_errors: None,
                            }),
                        );
                    }
                } else {
                    // Si está ACTIVE o SUSPENDED, sí bloquea la creación
                    if email == trimmed_email {
                        conflict_errors.insert("email".to_string(), "Este correo electrónico ya está registrado.".to_string());
                    }
                    if phone == trimmed_phone {
                        conflict_errors.insert("phone".to_string(), "Este número de teléfono ya está registrado.".to_string());
                    }
                }
            }
            if !conflict_errors.is_empty() {
                return (
                    StatusCode::CONFLICT,
                    Json(ApiResponse {
                        success: false,
                        message: "No se pudo completar el registro por datos duplicados.".to_string(),
                        field_errors: Some(conflict_errors),
                    }),
                );
            }
        }
        Err(e) => {
            eprintln!("Error al verificar usuarios existentes: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiResponse {
                    success: false,
                    message: "Error interno del servidor al validar credenciales existentes.".to_string(),
                    field_errors: None,
                }),
            );
        }
    }

    // 6. Hashear la contraseña con Argon2
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();

    let password_hash = match argon2.hash_password(payload.password.as_bytes(), &salt) {
        Ok(hash) => hash.to_string(),
        Err(_) => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiResponse {
                    success: false,
                    message: "Error interno del servidor al procesar la contraseña.".to_string(),
                    field_errors: None,
                }),
            );
        }
    };

    // 7. Insertar en la base de datos (estado PENDING hasta verificación)
    let insert_result = sqlx::query(
        "INSERT INTO users (name, email, telefono, password) VALUES ($1, $2, $3, $4)"
    )
    .bind(trimmed_name)
    .bind(trimmed_email)
    .bind(trimmed_phone)
    .bind(&password_hash)
    .execute(&state.pool)
    .await;

    match insert_result {
        Ok(_) => (
            StatusCode::CREATED,
            Json(ApiResponse {
                success: true,
                message: "Registro exitoso. Verifica tu correo electrónico para activar tu cuenta.".to_string(),
                field_errors: None,
            }),
        ),
        Err(e) => {
            let error_string = e.to_string();
            let mut conflict_errors = HashMap::new();

            if error_string.contains("users_email_key") {
                conflict_errors.insert("email".to_string(), "Este correo electrónico ya está registrado.".to_string());
            } else if error_string.contains("users_telefono_key") {
                conflict_errors.insert("phone".to_string(), "Este número de teléfono ya está registrado.".to_string());
            }

            let status = if !conflict_errors.is_empty() {
                StatusCode::CONFLICT
            } else {
                StatusCode::INTERNAL_SERVER_ERROR
            };

            let message = if !conflict_errors.is_empty() {
                "No se pudo completar el registro por datos duplicados.".to_string()
            } else {
                "Error interno del servidor al registrar el usuario.".to_string()
            };

            (
                status,
                Json(ApiResponse {
                    success: false,
                    message,
                    field_errors: if conflict_errors.is_empty() { None } else { Some(conflict_errors) },
                }),
            )
        }
    }
}

// ─── POST /login ─────────────────────────────────────────────────────────

pub async fn login(
    State(state): State<AppState>,
    Json(payload): Json<LoginDto>,
) -> (StatusCode, Json<LoginResponse>) {
    // 1. Buscar al usuario por email
    let user = sqlx::query_as::<_, (Uuid, String, String, String, String, i32, Option<chrono::DateTime<chrono::Utc>>, String)>(
        "SELECT id, name, email, password, rol::TEXT, COALESCE(intentos_fallidos, 0), bloqueado_hasta, estado::TEXT FROM users WHERE email = $1"
    )
    .bind(&payload.email)
    .fetch_optional(&state.pool)
    .await;

    let (user_id, name, email, password_hash, role, intentos_fallidos, bloqueado_hasta, status) = match user {
        Ok(Some(u)) => u,
        Ok(None) => {
            return (
                StatusCode::UNAUTHORIZED,
                Json(LoginResponse {
                    success: false,
                    message: "Credenciales inválidas.".to_string(),
                    access_token: None,
                    refresh_token: None,
                    user: None,
                }),
            );
        }
        Err(e) => {
            eprintln!("Error al buscar usuario: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(LoginResponse {
                    success: false,
                    message: "Error interno del servidor.".to_string(),
                    access_token: None,
                    refresh_token: None,
                    user: None,
                }),
            );
        }
    };

    // 2. Verificar si el usuario está verificado (ACTIVE)
    if status != "ACTIVE" {
        return (
            StatusCode::FORBIDDEN,
            Json(LoginResponse {
                success: false,
                message: "Tu cuenta no ha sido verificada. Revisa tu correo electrónico.".to_string(),
                access_token: None,
                refresh_token: None,
                user: None,
            }),
        );
    }

    // 3. Verificar si la cuenta está bloqueada
    if let Some(bloqueado) = bloqueado_hasta {
        if bloqueado > Utc::now() {
            return (
                StatusCode::FORBIDDEN,
                Json(LoginResponse {
                    success: false,
                    message: "Cuenta bloqueada temporalmente por demasiados intentos fallidos. Intenta más tarde.".to_string(),
                    access_token: None,
                    refresh_token: None,
                    user: None,
                }),
            );
        }
    }

    // 4. Verificar contraseña con Argon2
    let parsed_hash = match PasswordHash::new(&password_hash) {
        Ok(h) => h,
        Err(_) => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(LoginResponse {
                    success: false,
                    message: "Error interno al procesar credenciales.".to_string(),
                    access_token: None,
                    refresh_token: None,
                    user: None,
                }),
            );
        }
    };

    let argon2 = Argon2::default();
    if argon2.verify_password(payload.password.as_bytes(), &parsed_hash).is_err() {
        // Incrementar intentos fallidos
        let nuevos_intentos = intentos_fallidos + 1;
        if nuevos_intentos >= 5 {
            // Bloquear por 15 minutos
            let bloqueo_hasta = Utc::now() + Duration::minutes(15);
            if let Err(e) = sqlx::query(
                "UPDATE users SET intentos_fallidos = $1, bloqueado_hasta = $2 WHERE id = $3"
            )
            .bind(nuevos_intentos)
            .bind(bloqueo_hasta)
            .bind(user_id)
            .execute(&state.pool)
            .await {
                eprintln!("Error al actualizar intentos fallidos (bloqueo): {}", e);
            }

            return (
                StatusCode::FORBIDDEN,
                Json(LoginResponse {
                    success: false,
                    message: "Cuenta bloqueada por 15 minutos debido a demasiados intentos fallidos.".to_string(),
                    access_token: None,
                    refresh_token: None,
                    user: None,
                }),
            );
        } else {
            if let Err(e) = sqlx::query(
                "UPDATE users SET intentos_fallidos = $1 WHERE id = $2"
            )
            .bind(nuevos_intentos)
            .bind(user_id)
            .execute(&state.pool)
            .await {
                eprintln!("Error al actualizar intentos fallidos: {}", e);
            }
        }

        return (
            StatusCode::UNAUTHORIZED,
            Json(LoginResponse {
                success: false,
                message: "Credenciales inválidas.".to_string(),
                access_token: None,
                refresh_token: None,
                user: None,
            }),
        );
    }

    // 5. Login exitoso — resetear intentos fallidos
    if let Err(e) = sqlx::query(
        "UPDATE users SET intentos_fallidos = 0, bloqueado_hasta = NULL WHERE id = $1"
    )
    .bind(user_id)
    .execute(&state.pool)
    .await {
        eprintln!("Error al reiniciar intentos fallidos: {}", e);
    }

    // 6. Generar JWT access token (15 min)
    let access_token = match generate_access_token(user_id, &role, &state.config.jwt_secret) {
        Ok(t) => t,
        Err(e) => {
            eprintln!("Error al generar access token: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(LoginResponse {
                    success: false,
                    message: "Error interno al generar token de acceso.".to_string(),
                    access_token: None,
                    refresh_token: None,
                    user: None,
                }),
            );
        }
    };

    // 7. Generar refresh token (UUID, guardado en DB, 7 días)
    let refresh_token_id = Uuid::new_v4();
    let refresh_expires = Utc::now() + Duration::days(7);
    if let Err(e) = sqlx::query(
        "INSERT INTO refresh_tokens (token, user_id, expires_at) VALUES ($1, $2, $3)"
    )
    .bind(refresh_token_id)
    .bind(user_id)
    .bind(refresh_expires)
    .execute(&state.pool)
    .await {
        eprintln!("Error al insertar refresh token en BD: {}", e);
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(LoginResponse {
                success: false,
                message: "Error interno al iniciar sesión.".to_string(),
                access_token: None,
                refresh_token: None,
                user: None,
            }),
        );
    }

    (
        StatusCode::OK,
        Json(LoginResponse {
            success: true,
            message: "Inicio de sesión exitoso.".to_string(),
            access_token: Some(access_token),
            refresh_token: Some(refresh_token_id.to_string()),
            user: Some(LoginUserInfo {
                id: user_id,
                name,
                email,
                role,
            }),
        }),
    )
}

// ─── PUT /admin/users/:id/role ───────────────────────────────────────────

pub async fn change_user_role(
    State(state): State<AppState>,
    axum::extract::Path(target_user_id): axum::extract::Path<Uuid>,
    axum::Extension(auth_user): axum::Extension<crate::auth::middleware::AuthUser>,
    Json(payload): Json<ChangeRoleDto>,
) -> (StatusCode, Json<ApiResponse>) {
    // Verificar que no se cambie el rol a sí mismo
    if auth_user.user_id == target_user_id {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiResponse {
                success: false,
                message: "No puedes cambiar tu propio rol.".to_string(),
                field_errors: None,
            }),
        );
    }

    // Validar que el rol sea válido
    let valid_roles = ["USER", "ADMIN", "MODERATOR"];
    if !valid_roles.contains(&payload.role.as_str()) {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiResponse {
                success: false,
                message: format!("Rol inválido. Los roles válidos son: {}", valid_roles.join(", ")),
                field_errors: None,
            }),
        );
    }

    // Actualizar el rol del usuario
    let result = sqlx::query(
        "UPDATE users SET rol = $1::text::roles WHERE id = $2"
    )
    .bind(&payload.role)
    .bind(target_user_id)
    .execute(&state.pool)
    .await;

    match result {
        Ok(r) => {
            if r.rows_affected() == 0 {
                return (
                    StatusCode::NOT_FOUND,
                    Json(ApiResponse {
                        success: false,
                        message: "No se encontró el usuario especificado.".to_string(),
                        field_errors: None,
                    }),
                );
            }

            // Invalidar todos los refresh tokens del usuario afectado
            if let Err(e) = sqlx::query(
                "DELETE FROM refresh_tokens WHERE user_id = $1"
            )
            .bind(target_user_id)
            .execute(&state.pool)
            .await {
                eprintln!("Error al eliminar refresh tokens del usuario modificado: {}", e);
            }

            (
                StatusCode::OK,
                Json(ApiResponse {
                    success: true,
                    message: format!("Rol del usuario actualizado a '{}'.", payload.role),
                    field_errors: None,
                }),
            )
        }
        Err(e) => {
            eprintln!("Error al cambiar rol: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiResponse {
                    success: false,
                    message: "Error interno al actualizar el rol.".to_string(),
                    field_errors: None,
                }),
            )
        }
    }
}