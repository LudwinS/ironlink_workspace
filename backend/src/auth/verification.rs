use axum::extract::State;
use axum::http::StatusCode;
use axum::Json;
use chrono::{Duration, Utc};
use rand::Rng;
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use uuid::Uuid;

use crate::auth::service::ApiResponse;
use crate::config::AppConfig;
use crate::mailer;

/// Estado compartido para los endpoints de verificación
#[derive(Clone)]
pub struct AppState {
    pub pool: PgPool,
    pub config: std::sync::Arc<AppConfig>,
    pub mailer: mailer::SmtpMailer,
}

// ─── DTOs ────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub struct RequestVerificationDto {
    pub email: String,
    pub method: String, // "code" o "link"
}

#[derive(Deserialize)]
pub struct VerifyEmailDto {
    pub email: String,
    pub code: String,
}

#[derive(Serialize)]
pub struct VerifyResponse {
    pub success: bool,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub user: Option<UserInfo>,
}

#[derive(Serialize)]
pub struct UserInfo {
    pub id: Uuid,
    pub name: String,
    pub email: String,
    pub role: String,
}

// ─── POST /request-verification ──────────────────────────────────────────

pub async fn request_verification(
    State(state): State<AppState>,
    Json(payload): Json<RequestVerificationDto>,
) -> (StatusCode, Json<ApiResponse>) {
    // 1. Buscar al usuario por email
    let user = sqlx::query_as::<_, (Uuid, String)>(
        "SELECT id, estado::TEXT FROM users WHERE email = $1"
    )
    .bind(&payload.email)
    .fetch_optional(&state.pool)
    .await;

    let (user_id, status) = match user {
        Ok(Some(u)) => u,
        Ok(None) => {
            return (
                StatusCode::NOT_FOUND,
                Json(ApiResponse {
                    success: false,
                    message: "No se encontró un usuario con ese correo electrónico.".to_string(),
                    field_errors: None,
                }),
            );
        }
        Err(_) => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiResponse {
                    success: false,
                    message: "Error interno al buscar el usuario.".to_string(),
                    field_errors: None,
                }),
            );
        }
    };

    // Si ya está activo, no necesita verificación
    if status == "ACTIVE" {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiResponse {
                success: false,
                message: "Esta cuenta ya está verificada.".to_string(),
                field_errors: None,
            }),
        );
    }

    // 2. Verificar límite de 3 solicitudes por hora
    let count_result = sqlx::query_as::<_, (i64,)>(
        "SELECT COUNT(*) FROM verification_tokens WHERE user_id = $1 AND created_at > NOW() - INTERVAL '1 hour'"
    )
    .bind(user_id)
    .fetch_one(&state.pool)
    .await;

    let count = match count_result {
        Ok(c) => c.0,
        Err(e) => {
            eprintln!("Error al verificar límite de solicitudes: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiResponse {
                    success: false,
                    message: "Error interno al procesar la verificación.".to_string(),
                    field_errors: None,
                }),
            );
        }
    };

    if count >= 3 {
        return (
            StatusCode::TOO_MANY_REQUESTS,
            Json(ApiResponse {
                success: false,
                message: "Has excedido el límite de solicitudes. Intenta de nuevo en una hora.".to_string(),
                field_errors: None,
            }),
        );
    }

    // 3. Generar código o token según el método
    let expires_at = Utc::now() + Duration::minutes(10);

    if payload.method == "link" {
        // Generar token de 64 caracteres hexadecimales (32 bytes)
        let token_hex = {
            let mut rng = rand::thread_rng();
            let mut bytes = [0u8; 32];
            rng.fill(&mut bytes);
            hex::encode(bytes)
        };
        let code = "000000"; // Placeholder, no se usa para links

        let insert_result = sqlx::query(
            "INSERT INTO verification_tokens (user_id, code, token, method, expires_at) VALUES ($1, $2, $3, 'link', $4)"
        )
        .bind(user_id)
        .bind(code)
        .bind(&token_hex)
        .bind(expires_at)
        .execute(&state.pool)
        .await;

        if let Err(e) = insert_result {
            eprintln!("Error al generar el token de verificación: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiResponse {
                    success: false,
                    message: "Error al generar el token de verificación.".to_string(),
                    field_errors: None,
                }),
            );
        }

        // Enviar enlace por correo
        let link = format!("{}/verify-link/{}", state.config.app_base_url, token_hex);
        if let Err(e) = mailer::send_verification_link(&state.mailer, &state.config.smtp_from, &payload.email, &link).await {
            eprintln!("Error al enviar correo de verificación: {}", e);
            // No retornamos error al usuario por temas de seguridad, el token queda guardado
        }
    } else {
        let code: String = {
            let mut rng = rand::thread_rng();
            format!("{:06}", rng.gen_range(0..1_000_000u32))
        };

        let insert_result = sqlx::query(
            "INSERT INTO verification_tokens (user_id, code, method, expires_at) VALUES ($1, $2, 'code', $3)"
        )
        .bind(user_id)
        .bind(&code)
        .bind(expires_at)
        .execute(&state.pool)
        .await;

        if let Err(e) = insert_result {
            eprintln!("Error al generar el código de verificación: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiResponse {
                    success: false,
                    message: "Error al generar el código de verificación.".to_string(),
                    field_errors: None,
                }),
            );
        }

        // Enviar código por correo
        if let Err(e) = mailer::send_verification_code(&state.mailer, &state.config.smtp_from, &payload.email, &code).await {
            eprintln!("Error al enviar correo de verificación: {}", e);
        }
    }

    (
        StatusCode::OK,
        Json(ApiResponse {
            success: true,
            message: "Se ha enviado la verificación a tu correo electrónico.".to_string(),
            field_errors: None,
        }),
    )
}

// ─── POST /verify-email ──────────────────────────────────────────────────

pub async fn verify_email(
    State(state): State<AppState>,
    Json(payload): Json<VerifyEmailDto>,
) -> (StatusCode, Json<VerifyResponse>) {
    // 1. Buscar al usuario
    let user = sqlx::query_as::<_, (Uuid, String, String, String)>(
        "SELECT id, name, rol::TEXT, estado::TEXT FROM users WHERE email = $1"
    )
    .bind(&payload.email)
    .fetch_optional(&state.pool)
    .await;

    let (user_id, name, role, estado) = match user {
        Ok(Some(u)) => u,
        Ok(None) => {
            return (
                StatusCode::NOT_FOUND,
                Json(VerifyResponse {
                    success: false,
                    message: "No se encontró un usuario con ese correo.".to_string(),
                    user: None,
                }),
            );
        }
        Err(_) => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(VerifyResponse {
                    success: false,
                    message: "Error interno del servidor.".to_string(),
                    user: None,
                }),
            );
        }
    };

    // Si el usuario ya está activo (por ejemplo, verificado mediante enlace)
    if estado == "ACTIVE" {
        return (
            StatusCode::OK,
            Json(VerifyResponse {
                success: true,
                message: "Cuenta ya verificada exitosamente.".to_string(),
                user: Some(UserInfo {
                    id: user_id,
                    name,
                    email: payload.email,
                    role,
                }),
            }),
        );
    }

    // 2. Buscar token válido (no expirado, método code)
    let token_row = sqlx::query_as::<_, (Uuid,)>(
        "SELECT id FROM verification_tokens WHERE user_id = $1 AND code = $2 AND method = 'code' AND expires_at > NOW() ORDER BY created_at DESC LIMIT 1"
    )
    .bind(user_id)
    .bind(&payload.code)
    .fetch_optional(&state.pool)
    .await;

    let token_id = match token_row {
        Ok(Some(t)) => t.0,
        Ok(None) => {
            return (
                StatusCode::BAD_REQUEST,
                Json(VerifyResponse {
                    success: false,
                    message: "Código inválido o expirado.".to_string(),
                    user: None,
                }),
            );
        }
        Err(_) => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(VerifyResponse {
                    success: false,
                    message: "Error interno al validar el código.".to_string(),
                    user: None,
                }),
            );
        }
    };

    // Iniciar transacción
    let mut tx = match state.pool.begin().await {
        Ok(t) => t,
        Err(e) => {
            eprintln!("Error al iniciar transacción en verify_email: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(VerifyResponse {
                    success: false,
                    message: "Error interno al iniciar la verificación.".to_string(),
                    user: None,
                }),
            );
        }
    };

    // 3. Marcar usuario como ACTIVE
    let update_res = sqlx::query("UPDATE users SET estado = 'ACTIVE' WHERE id = $1")
        .bind(user_id)
        .execute(&mut *tx)
        .await;

    if let Err(e) = update_res {
        eprintln!("Error al actualizar estado del usuario a ACTIVE: {}", e);
        let _ = tx.rollback().await;
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(VerifyResponse {
                success: false,
                message: "Error interno al activar la cuenta.".to_string(),
                user: None,
            }),
        );
    }

    // 4. Eliminar el token usado
    let delete_res = sqlx::query("DELETE FROM verification_tokens WHERE id = $1")
        .bind(token_id)
        .execute(&mut *tx)
        .await;

    if let Err(e) = delete_res {
        eprintln!("Error al eliminar el token de verificación usado: {}", e);
        let _ = tx.rollback().await;
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(VerifyResponse {
                success: false,
                message: "Error interno al limpiar el código de verificación.".to_string(),
                user: None,
            }),
        );
    }

    if let Err(e) = tx.commit().await {
        eprintln!("Error al confirmar transacción en verify_email: {}", e);
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(VerifyResponse {
                success: false,
                message: "Error interno al completar la verificación.".to_string(),
                user: None,
            }),
        );
    }

    (
        StatusCode::OK,
        Json(VerifyResponse {
            success: true,
            message: "Cuenta verificada exitosamente.".to_string(),
            user: Some(UserInfo {
                id: user_id,
                name,
                email: payload.email,
                role,
            }),
        }),
    )
}

// ─── GET /verify-link/:token ─────────────────────────────────────────────

pub async fn verify_link(
    State(state): State<AppState>,
    axum::extract::Path(token): axum::extract::Path<String>,
) -> (StatusCode, Json<VerifyResponse>) {
    // 1. Buscar token válido (no expirado, método link)
    let token_row = sqlx::query_as::<_, (Uuid, Uuid)>(
        "SELECT id, user_id FROM verification_tokens WHERE token = $1 AND method = 'link' AND expires_at > NOW() LIMIT 1"
    )
    .bind(&token)
    .fetch_optional(&state.pool)
    .await;

    let (token_id, user_id) = match token_row {
        Ok(Some(t)) => t,
        Ok(None) => {
            return (
                StatusCode::BAD_REQUEST,
                Json(VerifyResponse {
                    success: false,
                    message: "Enlace de verificación inválido o expirado.".to_string(),
                    user: None,
                }),
            );
        }
        Err(_) => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(VerifyResponse {
                    success: false,
                    message: "Error interno al validar el enlace.".to_string(),
                    user: None,
                }),
            );
        }
    };

    // 2. Obtener datos del usuario
    let user = sqlx::query_as::<_, (String, String, String)>(
        "SELECT name, email, rol::TEXT FROM users WHERE id = $1"
    )
    .bind(user_id)
    .fetch_optional(&state.pool)
    .await;

    let (name, email, role) = match user {
        Ok(Some(u)) => u,
        _ => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(VerifyResponse {
                    success: false,
                    message: "Error al obtener datos del usuario.".to_string(),
                    user: None,
                }),
            );
        }
    };

    // Iniciar transacción
    let mut tx = match state.pool.begin().await {
        Ok(t) => t,
        Err(e) => {
            eprintln!("Error al iniciar transacción en verify_link: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(VerifyResponse {
                    success: false,
                    message: "Error interno al iniciar la verificación.".to_string(),
                    user: None,
                }),
            );
        }
    };

    // 3. Marcar usuario como ACTIVE
    let update_res = sqlx::query("UPDATE users SET estado = 'ACTIVE' WHERE id = $1")
        .bind(user_id)
        .execute(&mut *tx)
        .await;

    if let Err(e) = update_res {
        eprintln!("Error al actualizar estado del usuario a ACTIVE: {}", e);
        let _ = tx.rollback().await;
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(VerifyResponse {
                success: false,
                message: "Error interno al activar la cuenta.".to_string(),
                user: None,
            }),
        );
    }

    // 4. Eliminar el token usado
    let delete_res = sqlx::query("DELETE FROM verification_tokens WHERE id = $1")
        .bind(token_id)
        .execute(&mut *tx)
        .await;

    if let Err(e) = delete_res {
        eprintln!("Error al eliminar el token de verificación usado: {}", e);
        let _ = tx.rollback().await;
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(VerifyResponse {
                success: false,
                message: "Error interno al limpiar el enlace de verificación.".to_string(),
                user: None,
            }),
        );
    }

    if let Err(e) = tx.commit().await {
        eprintln!("Error al confirmar transacción en verify_link: {}", e);
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(VerifyResponse {
                success: false,
                message: "Error interno al completar la verificación.".to_string(),
                user: None,
            }),
        );
    }

    (
        StatusCode::OK,
        Json(VerifyResponse {
            success: true,
            message: "Cuenta verificada exitosamente.".to_string(),
            user: Some(UserInfo {
                id: user_id,
                name,
                email,
                role,
            }),
        }),
    )
}
