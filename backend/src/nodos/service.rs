use axum::extract::State;
use axum::http::StatusCode;
use axum::Json;
use rand::Rng;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::auth::middleware::AuthUser;
use crate::auth::verification::AppState;

// ─── DTOs ────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub struct CreateNodoDto {
    pub nombre: String,
    pub descripcion: Option<String>,
}

#[derive(Serialize)]
pub struct NodoResponse {
    pub success: bool,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub nodo: Option<NodoInfo>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub nodos: Option<Vec<NodoInfo>>,
}

#[derive(Serialize, Clone)]
pub struct NodoInfo {
    pub id: Uuid,
    pub nombre: String,
    pub descripcion: Option<String>,
    pub token_acceso: String,
    pub creador_id: Uuid,
    pub estado: String,
    pub rol: Option<String>,
    pub miembros_count: i64,
}

/// Genera un token de acceso aleatorio de 32 caracteres hexadecimales
fn generate_access_token() -> String {
    let mut rng = rand::thread_rng();
    let mut bytes = [0u8; 16];
    rng.fill(&mut bytes);
    hex::encode(bytes)
}

// ─── POST /nodos ─────────────────────────────────────────────────────────

pub async fn create_nodo(
    State(state): State<AppState>,
    axum::Extension(auth_user): axum::Extension<AuthUser>,
    Json(payload): Json<CreateNodoDto>,
) -> (StatusCode, Json<NodoResponse>) {
    let token_acceso = generate_access_token();

    // Iniciar transacción
    let mut tx = match state.pool.begin().await {
        Ok(t) => t,
        Err(e) => {
            eprintln!("Error al iniciar transacción al crear nodo: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(NodoResponse {
                    success: false,
                    message: "Error interno al iniciar la creación del nodo.".to_string(),
                    nodo: None,
                    nodos: None,
                }),
            );
        }
    };

    let result = sqlx::query_as::<_, (Uuid, String, Option<String>, String, Uuid, String)>(
        "INSERT INTO nodos (nombre, descripcion, token_acceso, creador_id) VALUES ($1, $2, $3, $4) RETURNING id, nombre, descripcion, token_acceso, creador_id, estado"
    )
    .bind(&payload.nombre)
    .bind(&payload.descripcion)
    .bind(&token_acceso)
    .bind(auth_user.user_id)
    .fetch_one(&mut *tx)
    .await;

    match result {
        Ok((id, nombre, descripcion, token_acceso, creador_id, estado)) => {
            // También agregar al creador como miembro con rol OWNER
            let member_result = sqlx::query(
                "INSERT INTO nodo_miembros (nodo_id, user_id, rol) VALUES ($1, $2, 'OWNER')"
            )
            .bind(id)
            .bind(auth_user.user_id)
            .execute(&mut *tx)
            .await;

            if let Err(e) = member_result {
                eprintln!("Error al asociar miembro creador: {}", e);
                let _ = tx.rollback().await;
                return (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(NodoResponse {
                        success: false,
                        message: "Error interno al asociar el creador al nodo.".to_string(),
                        nodo: None,
                        nodos: None,
                    }),
                );
            }

            if let Err(e) = tx.commit().await {
                eprintln!("Error al confirmar transacción del nodo: {}", e);
                return (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(NodoResponse {
                        success: false,
                        message: "Error interno al confirmar la creación del nodo.".to_string(),
                        nodo: None,
                        nodos: None,
                    }),
                );
            }

            (
                StatusCode::CREATED,
                Json(NodoResponse {
                    success: true,
                    message: "Nodo creado exitosamente.".to_string(),
                    nodo: Some(NodoInfo {
                        id,
                        nombre,
                        descripcion,
                        token_acceso,
                        creador_id,
                        estado,
                        rol: Some("OWNER".to_string()),
                        miembros_count: 1,
                    }),
                    nodos: None,
                }),
            )
        }
        Err(e) => {
            eprintln!("Error al crear nodo: {}", e);
            let _ = tx.rollback().await;
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(NodoResponse {
                    success: false,
                    message: "Error interno al crear el nodo.".to_string(),
                    nodo: None,
                    nodos: None,
                }),
            )
        }
    }
}

// ─── GET /nodos ──────────────────────────────────────────────────────────

pub async fn list_nodos(
    State(state): State<AppState>,
    axum::Extension(auth_user): axum::Extension<AuthUser>,
) -> (StatusCode, Json<NodoResponse>) {
    // Obtener nodos donde el usuario es miembro o creador, contando sus participantes
    let rows = sqlx::query_as::<_, (Uuid, String, Option<String>, String, Uuid, String, String, i64)>(
        r#"
        SELECT n.id, n.nombre, n.descripcion, n.token_acceso, n.creador_id, n.estado, nm.rol,
               (SELECT COUNT(*) FROM nodo_miembros WHERE nodo_id = n.id) as miembros_count
        FROM nodos n
        INNER JOIN nodo_miembros nm ON n.id = nm.nodo_id
        WHERE nm.user_id = $1
        ORDER BY n.created_at DESC
        "#
    )
    .bind(auth_user.user_id)
    .fetch_all(&state.pool)
    .await;

    match rows {
        Ok(nodos) => {
            let nodo_list: Vec<NodoInfo> = nodos
                .into_iter()
                .map(|(id, nombre, descripcion, token_acceso, creador_id, estado, rol, miembros_count)| {
                    NodoInfo {
                        id,
                        nombre,
                        descripcion,
                        token_acceso,
                        creador_id,
                        estado,
                        rol: Some(rol),
                        miembros_count,
                    }
                })
                .collect();

            (
                StatusCode::OK,
                Json(NodoResponse {
                    success: true,
                    message: format!("Se encontraron {} nodo(s).", nodo_list.len()),
                    nodo: None,
                    nodos: Some(nodo_list),
                }),
            )
        }
        Err(e) => {
            eprintln!("Error al listar nodos: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(NodoResponse {
                    success: false,
                    message: "Error interno al listar los nodos.".to_string(),
                    nodo: None,
                    nodos: None,
                }),
            )
        }
    }
}

// ─── POST /nodos/join/:token ─────────────────────────────────────────────

pub async fn join_nodo(
    State(state): State<AppState>,
    axum::Extension(auth_user): axum::Extension<AuthUser>,
    axum::extract::Path(token): axum::extract::Path<String>,
) -> (StatusCode, Json<NodoResponse>) {
    // 1. Buscar nodo por token de acceso
    let nodo = sqlx::query_as::<_, (Uuid, String, Option<String>, String, Uuid, String)>(
        "SELECT id, nombre, descripcion, token_acceso, creador_id, estado FROM nodos WHERE token_acceso = $1 AND estado = 'active'"
    )
    .bind(&token)
    .fetch_optional(&state.pool)
    .await;

    let (nodo_id, nombre, descripcion, token_acceso, creador_id, estado) = match nodo {
        Ok(Some(n)) => n,
        Ok(None) => {
            return (
                StatusCode::NOT_FOUND,
                Json(NodoResponse {
                    success: false,
                    message: "No se encontró un nodo activo con ese token de acceso.".to_string(),
                    nodo: None,
                    nodos: None,
                }),
            );
        }
        Err(e) => {
            eprintln!("Error al buscar nodo: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(NodoResponse {
                    success: false,
                    message: "Error interno al buscar el nodo.".to_string(),
                    nodo: None,
                    nodos: None,
                }),
            );
        }
    };

    // 2. Verificar si ya es miembro
    let existing = sqlx::query_as::<_, (String,)>(
        "SELECT rol FROM nodo_miembros WHERE nodo_id = $1 AND user_id = $2"
    )
    .bind(nodo_id)
    .bind(auth_user.user_id)
    .fetch_optional(&state.pool)
    .await;

    if let Ok(Some(_)) = existing {
        return (
            StatusCode::CONFLICT,
            Json(NodoResponse {
                success: false,
                message: "Ya eres miembro de este nodo.".to_string(),
                nodo: None,
                nodos: None,
            }),
        );
    }

    // 3. Agregar como miembro
    let insert = sqlx::query(
        "INSERT INTO nodo_miembros (nodo_id, user_id, rol) VALUES ($1, $2, 'MEMBER')"
    )
    .bind(nodo_id)
    .bind(auth_user.user_id)
    .execute(&state.pool)
    .await;

    match insert {
        Ok(_) => {
            // Contar el número total de miembros después de unirse
            let count_row = sqlx::query_as::<_, (i64,)>(
                "SELECT COUNT(*) FROM nodo_miembros WHERE nodo_id = $1"
            )
            .bind(nodo_id)
            .fetch_one(&state.pool)
            .await;

            let miembros_count = count_row.map(|r| r.0).unwrap_or(1);

            (
                StatusCode::OK,
                Json(NodoResponse {
                    success: true,
                    message: "Te has unido al nodo exitosamente.".to_string(),
                    nodo: Some(NodoInfo {
                        id: nodo_id,
                        nombre,
                        descripcion,
                        token_acceso,
                        creador_id,
                        estado,
                        rol: Some("MEMBER".to_string()),
                        miembros_count,
                    }),
                    nodos: None,
                }),
            )
        }
        Err(e) => {
            eprintln!("Error al unirse al nodo: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(NodoResponse {
                    success: false,
                    message: "Error interno al unirse al nodo.".to_string(),
                    nodo: None,
                    nodos: None,
                }),
            )
        }
    }
}

// ─── DELETE /nodos/{id} ──────────────────────────────────────────────────

pub async fn delete_nodo(
    State(state): State<AppState>,
    axum::Extension(auth_user): axum::Extension<AuthUser>,
    axum::extract::Path(id): axum::extract::Path<Uuid>,
) -> (StatusCode, Json<NodoResponse>) {
    // 1. Verificar si el nodo existe y quién es el creador
    let creator_check = sqlx::query_as::<_, (Uuid,)>(
        "SELECT creador_id FROM nodos WHERE id = $1"
    )
    .bind(id)
    .fetch_optional(&state.pool)
    .await;

    let creador_id = match creator_check {
        Ok(Some((c_id,))) => c_id,
        Ok(None) => {
            return (
                StatusCode::NOT_FOUND,
                Json(NodoResponse {
                    success: false,
                    message: "No se encontró el nodo especificado.".to_string(),
                    nodo: None,
                    nodos: None,
                }),
            );
        }
        Err(e) => {
            eprintln!("Error al verificar el creador del nodo: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(NodoResponse {
                    success: false,
                    message: "Error interno al verificar el nodo.".to_string(),
                    nodo: None,
                    nodos: None,
                }),
            );
        }
    };

    // 2. Comprobar permisos (creador del nodo o administrador global)
    if creador_id != auth_user.user_id && auth_user.role != "ADMIN" {
        return (
            StatusCode::FORBIDDEN,
            Json(NodoResponse {
                success: false,
                message: "No tienes permisos para eliminar este nodo.".to_string(),
                nodo: None,
                nodos: None,
            }),
        );
    }

    // 3. Eliminar el nodo (el ON DELETE CASCADE se encargará de nodo_miembros)
    let delete_result = sqlx::query(
        "DELETE FROM nodos WHERE id = $1"
    )
    .bind(id)
    .execute(&state.pool)
    .await;

    match delete_result {
        Ok(_) => {
            (
                StatusCode::OK,
                Json(NodoResponse {
                    success: true,
                    message: "Nodo eliminado exitosamente.".to_string(),
                    nodo: None,
                    nodos: None,
                }),
            )
        }
        Err(e) => {
            eprintln!("Error al eliminar el nodo: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(NodoResponse {
                    success: false,
                    message: "Error interno al eliminar el nodo.".to_string(),
                    nodo: None,
                    nodos: None,
                }),
            )
        }
    }
}

