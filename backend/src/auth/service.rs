use serde::{Deserialize, Serialize};
use axum::extract::State;
use axum::http::StatusCode;
use axum::Json;
use sqlx::PgPool;
use std::collections::HashMap;
use argon2::{
    password_hash::{rand_core::OsRng, PasswordHasher, SaltString},
    Argon2
};

#[derive(Deserialize)]
pub struct RegisterUserDto {
    pub name: String,
    pub email: String,
    pub phone: String,
    pub password: String
}

#[derive(Serialize)]
pub struct ApiResponse {
    pub success: bool,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub field_errors: Option<HashMap<String, String>>,
}

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

pub async fn register_user(
    State(pool): State<PgPool>,
    Json(payload): Json<RegisterUserDto>,
) -> (StatusCode, Json<ApiResponse>) {

    // 1. Validar contraseña con criterios de seguridad
    let password_errors = validate_password(&payload.password);
    if !password_errors.is_empty() {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiResponse {
                success: false,
                message: "La contraseña no cumple los criterios de seguridad.".to_string(),
                field_errors: Some(password_errors),
            }),
        );
    }

    // 2. Hashear la contraseña con Argon2
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

    // 3. Insertar en la base de datos
    let insert_result = sqlx::query!(
        r#"
        INSERT INTO users (name, email, telefono, password)
        VALUES ($1, $2, $3, $4)
        "#,
        payload.name,
        payload.email,
        payload.phone,
        password_hash
    )
    .execute(&pool)
    .await;

    match insert_result {
        Ok(_) => (
            StatusCode::CREATED,
            Json(ApiResponse {
                success: true,
                message: "Registro exitoso. El usuario ha sido creado.".to_string(),
                field_errors: None,
            }),
        ),
        Err(e) => {
            let error_string = e.to_string();
            let mut field_errors = HashMap::new();

            if error_string.contains("users_email_key") {
                field_errors.insert("email".to_string(), "Este correo electrónico ya está registrado.".to_string());
            } else if error_string.contains("users_telefono_key") {
                field_errors.insert("phone".to_string(), "Este número de teléfono ya está registrado.".to_string());
            }

            let status = if !field_errors.is_empty() {
                StatusCode::CONFLICT
            } else {
                StatusCode::INTERNAL_SERVER_ERROR
            };

            let message = if !field_errors.is_empty() {
                "No se pudo completar el registro por datos duplicados.".to_string()
            } else {
                "Error interno del servidor al registrar el usuario.".to_string()
            };

            (
                status,
                Json(ApiResponse {
                    success: false,
                    message,
                    field_errors: if field_errors.is_empty() { None } else { Some(field_errors) },
                }),
            )
        }
    }
}