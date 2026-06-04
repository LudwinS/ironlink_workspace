use axum::{
    extract::Request,
    http::StatusCode,
    middleware::Next,
    response::{IntoResponse, Response},
    Json,
};
use serde_json::json;

use crate::auth::jwt::{validate_token, Claims};
use crate::config::AppConfig;

/// Datos del usuario autenticado, disponibles como extensión en las rutas protegidas
#[derive(Clone, Debug)]
pub struct AuthUser {
    pub user_id: uuid::Uuid,
    pub role: String,
}

/// Middleware de autenticación JWT.
/// Extrae el token del header Authorization: Bearer <token>,
/// lo valida y agrega AuthUser como extensión del request.
pub async fn jwt_auth(
    request: Request,
    next: Next,
) -> Response {
    // Obtener la configuración del estado de la app
    let config = request
        .extensions()
        .get::<AppConfig>()
        .cloned();

    let config = match config {
        Some(c) => c,
        None => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({
                    "success": false,
                    "message": "Error interno: configuración no disponible"
                })),
            )
                .into_response();
        }
    };

    // Extraer el header Authorization
    let auth_header = request
        .headers()
        .get("Authorization")
        .and_then(|v| v.to_str().ok());

    println!("JWT Auth - Ruta: {} - Authorization Header: {:?}", request.uri().path(), auth_header);

    let token = match auth_header {
        Some(h) if h.starts_with("Bearer ") => &h[7..],
        _ => {
            println!("JWT Auth - ERROR: Header Authorization faltante o malformado");
            return (
                StatusCode::UNAUTHORIZED,
                Json(json!({
                    "success": false,
                    "message": "Token de autenticación requerido"
                })),
            )
                .into_response();
        }
    };

    // Validar el token
    match validate_token(token, &config.jwt_secret) {
        Ok(token_data) => {
            let claims: Claims = token_data.claims;
            let user_id = match uuid::Uuid::parse_str(&claims.sub) {
                Ok(id) => id,
                Err(_) => {
                    println!("JWT Auth - ERROR: ID de usuario malformado en claims: {}", claims.sub);
                    return (
                        StatusCode::UNAUTHORIZED,
                        Json(json!({
                            "success": false,
                            "message": "Token inválido: ID de usuario malformado"
                        })),
                    )
                        .into_response();
                }
            };

            println!("JWT Auth - ÉXITO: Usuario {} verificado con rol {}", user_id, claims.role);

            let auth_user = AuthUser {
                user_id,
                role: claims.role,
            };

            // Inyectar el usuario autenticado como extensión
            let mut request = request;
            request.extensions_mut().insert(auth_user);

            next.run(request).await
        }
        Err(e) => {
            println!("JWT Auth - ERROR: Token inválido o expirado. Detalle: {:?}", e);
            (
                StatusCode::UNAUTHORIZED,
                Json(json!({
                    "success": false,
                    "message": "Token inválido o expirado"
                })),
            )
                .into_response()
        }
    }
}

/// Middleware que verifica que el usuario tenga rol de administrador
pub async fn require_admin(
    request: Request,
    next: Next,
) -> Response {
    let auth_user = request.extensions().get::<AuthUser>().cloned();

    match auth_user {
        Some(user) if user.role == "ADMIN" => next.run(request).await,
        Some(_) => (
            StatusCode::FORBIDDEN,
            Json(json!({
                "success": false,
                "message": "Acceso denegado: se requiere rol de administrador"
            })),
        )
            .into_response(),
        None => (
            StatusCode::UNAUTHORIZED,
            Json(json!({
                "success": false,
                "message": "No autenticado"
            })),
        )
            .into_response(),
    }
}
