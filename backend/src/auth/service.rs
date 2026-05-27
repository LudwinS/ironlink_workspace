use serde::Deserialize;
use axum::extract::{Json, State};
use axum::response::IntoResponse;
use sqlx::PgPool;
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

pub fn is_password_secure(password: &str) -> bool {
    let has_upper = password.chars().any(|c| c.is_uppercase());
    let has_lower = password.chars().any(|c| c.is_lowercase());
    let has_digit = password.chars().any(|c| c.is_numeric());
    let is_long_enough = password.chars().count() >= 8;
    
    has_upper && has_lower && has_digit && is_long_enough
}

pub async fn register_user(
    State(pool): State<PgPool>,
    Json(payload): Json<RegisterUserDto>,
) -> impl IntoResponse {
    
    if !is_password_secure(&payload.password) {
        return "Rechazado: La contraseña no cumple con los criterios de seguridad mínimos.";
    }

    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();
    
    let password_hash = argon2.hash_password(payload.password.as_bytes(), &salt)
        .expect("Error crítico: Fallo en el motor de encriptación")
        .to_string();

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
        Ok(_) => "Registro exitoso. El usuario ha sido creado en la base de datos.",
        Err(_) => "Error: No se pudo registrar el usuario. Es posible que el correo o el teléfono ya estén en uso."
    }
}