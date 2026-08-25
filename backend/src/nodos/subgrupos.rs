use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::Json;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::auth::middleware::AuthUser;
use crate::auth::verification::AppState;

// ─── DTOs ────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub struct CreateSubgrupoDto {
    pub nombre: String,
    pub descripcion: Option<String>,
    pub es_privado: Option<bool>,
}

#[derive(Serialize, Clone)]
pub struct SubgrupoInfo {
    pub id: Uuid,
    pub nodo_id: Uuid,
    pub nombre: String,
    pub descripcion: Option<String>,
    pub es_privado: bool,
    pub creado_por: Uuid,
    pub created_at: DateTime<Utc>,
    pub miembros_count: i64,
    pub is_member: bool,
}

#[derive(Serialize)]
pub struct SubgrupoResponse {
    pub success: bool,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub subgrupo: Option<SubgrupoInfo>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub subgrupos: Option<Vec<SubgrupoInfo>>,
}

#[derive(Serialize)]
pub struct SubgrupoMiembroInfo {
    pub user_id: Uuid,
    pub name: String,
    pub email: String,
    pub avatar_color: Option<String>,
    pub joined_at: DateTime<Utc>,
}

#[derive(Serialize)]
pub struct SubgrupoMiembrosResponse {
    pub success: bool,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub miembros: Option<Vec<SubgrupoMiembroInfo>>,
}

// ─── POST /nodos/{id}/subgrupos ──────────────────────────────────────────

pub async fn create_subgrupo(
    State(state): State<AppState>,
    axum::Extension(auth_user): axum::Extension<AuthUser>,
    Path(nodo_id): Path<Uuid>,
    Json(payload): Json<CreateSubgrupoDto>,
) -> (StatusCode, Json<SubgrupoResponse>) {
    // 1. Validar que el usuario pertenezca al nodo
    let is_member = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS(SELECT 1 FROM nodo_miembros WHERE nodo_id = $1 AND user_id = $2)"
    )
    .bind(nodo_id)
    .bind(auth_user.user_id)
    .fetch_one(&state.pool)
    .await
    .unwrap_or(false);

    if !is_member {
        return (
            StatusCode::FORBIDDEN,
            Json(SubgrupoResponse {
                success: false,
                message: "No tienes permiso para crear subgrupos en este nodo.".to_string(),
                subgrupo: None,
                subgrupos: None,
            }),
        );
    }

    let nombre = payload.nombre.trim();
    if nombre.is_empty() {
        return (
            StatusCode::BAD_REQUEST,
            Json(SubgrupoResponse {
                success: false,
                message: "El nombre del subgrupo no puede estar vacío.".to_string(),
                subgrupo: None,
                subgrupos: None,
            }),
        );
    }

    let es_privado = payload.es_privado.unwrap_or(false);

    // 2. Iniciar transacción
    let mut tx = match state.pool.begin().await {
        Ok(t) => t,
        Err(e) => {
            eprintln!("Error iniciando tx en create_subgrupo: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(SubgrupoResponse {
                    success: false,
                    message: "Error interno al iniciar la creación del subgrupo.".to_string(),
                    subgrupo: None,
                    subgrupos: None,
                }),
            );
        }
    };

    let insert_res = sqlx::query_as::<_, (Uuid, Uuid, String, Option<String>, bool, Uuid, DateTime<Utc>)>(
        "INSERT INTO subgrupos (nodo_id, nombre, descripcion, es_privado, creado_por) 
         VALUES ($1, $2, $3, $4, $5) 
         RETURNING id, nodo_id, nombre, descripcion, es_privado, creado_por, created_at"
    )
    .bind(nodo_id)
    .bind(nombre)
    .bind(&payload.descripcion)
    .bind(es_privado)
    .bind(auth_user.user_id)
    .fetch_one(&mut *tx)
    .await;

    match insert_res {
        Ok((id, n_id, nom, desc, priv_flag, creador, created_at)) => {
            // Añadir al creador como miembro del subgrupo
            if let Err(e) = sqlx::query(
                "INSERT INTO subgrupo_miembros (subgrupo_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING"
            )
            .bind(id)
            .bind(auth_user.user_id)
            .execute(&mut *tx)
            .await {
                eprintln!("Error agregando creador al subgrupo: {}", e);
                let _ = tx.rollback().await;
                return (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(SubgrupoResponse {
                        success: false,
                        message: "Error al asociar al creador con el subgrupo.".to_string(),
                        subgrupo: None,
                        subgrupos: None,
                    }),
                );
            }

            if let Err(e) = tx.commit().await {
                eprintln!("Error al confirmar transacción de subgrupo: {}", e);
                return (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(SubgrupoResponse {
                        success: false,
                        message: "Error al guardar el subgrupo.".to_string(),
                        subgrupo: None,
                        subgrupos: None,
                    }),
                );
            }

            (
                StatusCode::CREATED,
                Json(SubgrupoResponse {
                    success: true,
                    message: "Subgrupo creado exitosamente.".to_string(),
                    subgrupo: Some(SubgrupoInfo {
                        id,
                        nodo_id: n_id,
                        nombre: nom,
                        descripcion: desc,
                        es_privado: priv_flag,
                        creado_por: creador,
                        created_at,
                        miembros_count: 1,
                        is_member: true,
                    }),
                    subgrupos: None,
                }),
            )
        }
        Err(e) => {
            eprintln!("Error al insertar subgrupo: {}", e);
            let _ = tx.rollback().await;
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(SubgrupoResponse {
                    success: false,
                    message: "Error interno al crear el subgrupo.".to_string(),
                    subgrupo: None,
                    subgrupos: None,
                }),
            )
        }
    }
}

// ─── GET /nodos/{id}/subgrupos ───────────────────────────────────────────

pub async fn list_subgrupos(
    State(state): State<AppState>,
    axum::Extension(auth_user): axum::Extension<AuthUser>,
    Path(nodo_id): Path<Uuid>,
) -> (StatusCode, Json<SubgrupoResponse>) {
    // 1. Validar que el usuario sea miembro del nodo
    let is_member = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS(SELECT 1 FROM nodo_miembros WHERE nodo_id = $1 AND user_id = $2)"
    )
    .bind(nodo_id)
    .bind(auth_user.user_id)
    .fetch_one(&state.pool)
    .await
    .unwrap_or(false);

    if !is_member {
        return (
            StatusCode::FORBIDDEN,
            Json(SubgrupoResponse {
                success: false,
                message: "No perteneces a este nodo.".to_string(),
                subgrupo: None,
                subgrupos: None,
            }),
        );
    }

    let query = "
        SELECT 
            s.id, 
            s.nodo_id, 
            s.nombre, 
            s.descripcion, 
            s.es_privado, 
            s.creado_por, 
            s.created_at,
            (SELECT COUNT(*) FROM subgrupo_miembros sm WHERE sm.subgrupo_id = s.id) AS miembros_count,
            EXISTS(SELECT 1 FROM subgrupo_miembros sm WHERE sm.subgrupo_id = s.id AND sm.user_id = $2) AS is_member
        FROM subgrupos s
        WHERE s.nodo_id = $1
        ORDER BY s.created_at ASC
    ";

    let rows = sqlx::query_as::<_, (Uuid, Uuid, String, Option<String>, bool, Uuid, DateTime<Utc>, i64, bool)>(query)
        .bind(nodo_id)
        .bind(auth_user.user_id)
        .fetch_all(&state.pool)
        .await;

    match rows {
        Ok(list) => {
            let subgrupos = list
                .into_iter()
                .map(|(id, n_id, nom, desc, priv_flag, creador, created_at, count, is_mem)| SubgrupoInfo {
                    id,
                    nodo_id: n_id,
                    nombre: nom,
                    descripcion: desc,
                    es_privado: priv_flag,
                    creado_por: creador,
                    created_at,
                    miembros_count: count,
                    is_member: is_mem,
                })
                .collect();

            (
                StatusCode::OK,
                Json(SubgrupoResponse {
                    success: true,
                    message: "Subgrupos listados exitosamente.".to_string(),
                    subgrupo: None,
                    subgrupos: Some(subgrupos),
                }),
            )
        }
        Err(e) => {
            eprintln!("Error al listar subgrupos: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(SubgrupoResponse {
                    success: false,
                    message: "Error interno al cargar los subgrupos.".to_string(),
                    subgrupo: None,
                    subgrupos: None,
                }),
            )
        }
    }
}

// ─── POST /nodos/{id}/subgrupos/{subgrupo_id}/join ──────────────────────

pub async fn join_subgrupo(
    State(state): State<AppState>,
    axum::Extension(auth_user): axum::Extension<AuthUser>,
    Path((nodo_id, subgrupo_id)): Path<(Uuid, Uuid)>,
) -> (StatusCode, Json<SubgrupoResponse>) {
    // 1. Validar que el usuario sea miembro del nodo
    let is_node_member = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS(SELECT 1 FROM nodo_miembros WHERE nodo_id = $1 AND user_id = $2)"
    )
    .bind(nodo_id)
    .bind(auth_user.user_id)
    .fetch_one(&state.pool)
    .await
    .unwrap_or(false);

    if !is_node_member {
        return (
            StatusCode::FORBIDDEN,
            Json(SubgrupoResponse {
                success: false,
                message: "No perteneces al nodo principal.".to_string(),
                subgrupo: None,
                subgrupos: None,
            }),
        );
    }

    // 2. Insertar en subgrupo_miembros
    let result = sqlx::query(
        "INSERT INTO subgrupo_miembros (subgrupo_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING"
    )
    .bind(subgrupo_id)
    .bind(auth_user.user_id)
    .execute(&state.pool)
    .await;

    match result {
        Ok(_) => (
            StatusCode::OK,
            Json(SubgrupoResponse {
                success: true,
                message: "Te has unido al subgrupo exitosamente.".to_string(),
                subgrupo: None,
                subgrupos: None,
            }),
        ),
        Err(e) => {
            eprintln!("Error al unirse al subgrupo: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(SubgrupoResponse {
                    success: false,
                    message: "Error interno al unirse al subgrupo.".to_string(),
                    subgrupo: None,
                    subgrupos: None,
                }),
            )
        }
    }
}

// ─── POST /nodos/{id}/subgrupos/{subgrupo_id}/leave ─────────────────────

pub async fn leave_subgrupo(
    State(state): State<AppState>,
    axum::Extension(auth_user): axum::Extension<AuthUser>,
    Path((_nodo_id, subgrupo_id)): Path<(Uuid, Uuid)>,
) -> (StatusCode, Json<SubgrupoResponse>) {
    let result = sqlx::query(
        "DELETE FROM subgrupo_miembros WHERE subgrupo_id = $1 AND user_id = $2"
    )
    .bind(subgrupo_id)
    .bind(auth_user.user_id)
    .execute(&state.pool)
    .await;

    match result {
        Ok(_) => (
            StatusCode::OK,
            Json(SubgrupoResponse {
                success: true,
                message: "Has salido del subgrupo.".to_string(),
                subgrupo: None,
                subgrupos: None,
            }),
        ),
        Err(e) => {
            eprintln!("Error al salir del subgrupo: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(SubgrupoResponse {
                    success: false,
                    message: "Error interno al salir del subgrupo.".to_string(),
                    subgrupo: None,
                    subgrupos: None,
                }),
            )
        }
    }
}

// ─── DELETE /nodos/{id}/subgrupos/{subgrupo_id} ─────────────────────────

pub async fn delete_subgrupo(
    State(state): State<AppState>,
    axum::Extension(auth_user): axum::Extension<AuthUser>,
    Path((nodo_id, subgrupo_id)): Path<(Uuid, Uuid)>,
) -> (StatusCode, Json<SubgrupoResponse>) {
    // 1. Validar que el usuario sea el creador del subgrupo o ADMIN/OWNER del nodo
    let is_creator_or_admin = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS(
            SELECT 1 FROM subgrupos s 
            LEFT JOIN nodo_miembros nm ON nm.nodo_id = s.nodo_id AND nm.user_id = $2
            WHERE s.id = $1 AND (s.creado_por = $2 OR nm.rol IN ('ADMIN', 'OWNER'))
        )"
    )
    .bind(subgrupo_id)
    .bind(auth_user.user_id)
    .fetch_one(&state.pool)
    .await
    .unwrap_or(false);

    if !is_creator_or_admin {
        return (
            StatusCode::FORBIDDEN,
            Json(SubgrupoResponse {
                success: false,
                message: "No tienes permiso para eliminar este subgrupo.".to_string(),
                subgrupo: None,
                subgrupos: None,
            }),
        );
    }

    let result = sqlx::query(
        "DELETE FROM subgrupos WHERE id = $1 AND nodo_id = $2"
    )
    .bind(subgrupo_id)
    .bind(nodo_id)
    .execute(&state.pool)
    .await;

    match result {
        Ok(r) => {
            if r.rows_affected() == 0 {
                (
                    StatusCode::NOT_FOUND,
                    Json(SubgrupoResponse {
                        success: false,
                        message: "Subgrupo no encontrado.".to_string(),
                        subgrupo: None,
                        subgrupos: None,
                    }),
                )
            } else {
                (
                    StatusCode::OK,
                    Json(SubgrupoResponse {
                        success: true,
                        message: "Subgrupo eliminado exitosamente.".to_string(),
                        subgrupo: None,
                        subgrupos: None,
                    }),
                )
            }
        }
        Err(e) => {
            eprintln!("Error al eliminar subgrupo: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(SubgrupoResponse {
                    success: false,
                    message: "Error interno al eliminar el subgrupo.".to_string(),
                    subgrupo: None,
                    subgrupos: None,
                }),
            )
        }
    }
}

// ─── GET /nodos/{id}/subgrupos/{subgrupo_id}/miembros ───────────────────

pub async fn list_subgrupo_miembros(
    State(state): State<AppState>,
    axum::Extension(auth_user): axum::Extension<AuthUser>,
    Path((nodo_id, subgrupo_id)): Path<(Uuid, Uuid)>,
) -> (StatusCode, Json<SubgrupoMiembrosResponse>) {
    // 1. Validar que el usuario pertenezca al nodo
    let is_member = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS(SELECT 1 FROM nodo_miembros WHERE nodo_id = $1 AND user_id = $2)"
    )
    .bind(nodo_id)
    .bind(auth_user.user_id)
    .fetch_one(&state.pool)
    .await
    .unwrap_or(false);

    if !is_member {
        return (
            StatusCode::FORBIDDEN,
            Json(SubgrupoMiembrosResponse {
                success: false,
                message: "No perteneces a este nodo.".to_string(),
                miembros: None,
            }),
        );
    }

    let rows = sqlx::query_as::<_, (Uuid, String, String, Option<String>, DateTime<Utc>)>(
        "SELECT u.id, u.name, u.email, u.avatar_color, sm.created_at
         FROM subgrupo_miembros sm
         JOIN users u ON sm.user_id = u.id
         WHERE sm.subgrupo_id = $1
         ORDER BY sm.created_at ASC"
    )
    .bind(subgrupo_id)
    .fetch_all(&state.pool)
    .await;

    match rows {
        Ok(list) => {
            let miembros = list
                .into_iter()
                .map(|(uid, name, email, color, joined)| SubgrupoMiembroInfo {
                    user_id: uid,
                    name,
                    email,
                    avatar_color: color,
                    joined_at: joined,
                })
                .collect();

            (
                StatusCode::OK,
                Json(SubgrupoMiembrosResponse {
                    success: true,
                    message: "Miembros del subgrupo listados exitosamente.".to_string(),
                    miembros: Some(miembros),
                }),
            )
        }
        Err(e) => {
            eprintln!("Error al listar miembros de subgrupo: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(SubgrupoMiembrosResponse {
                    success: false,
                    message: "Error interno al cargar los miembros del subgrupo.".to_string(),
                    miembros: None,
                }),
            )
        }
    }
}
