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
pub struct CreateReunionDto {
    pub titulo: String,
    pub descripcion: Option<String>,
    pub fecha_inicio: DateTime<Utc>,
    pub fecha_fin: Option<DateTime<Utc>>,
    pub enlace_reunion: Option<String>,
}

#[derive(Deserialize)]
pub struct UpdateReunionDto {
    pub titulo: Option<String>,
    pub descripcion: Option<String>,
    pub fecha_inicio: Option<DateTime<Utc>>,
    pub fecha_fin: Option<DateTime<Utc>>,
    pub enlace_reunion: Option<String>,
}

#[derive(Serialize, Clone)]
pub struct ReunionInfo {
    pub id: Uuid,
    pub nodo_id: Uuid,
    pub titulo: String,
    pub descripcion: Option<String>,
    pub fecha_inicio: DateTime<Utc>,
    pub fecha_fin: Option<DateTime<Utc>>,
    pub enlace_reunion: Option<String>,
    pub creado_por: Uuid,
    pub creador_nombre: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Serialize)]
pub struct ReunionResponse {
    pub success: bool,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub reunion: Option<ReunionInfo>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub reuniones: Option<Vec<ReunionInfo>>,
}

// ─── POST /nodos/{id}/reuniones ──────────────────────────────────────────

pub async fn create_reunion(
    State(state): State<AppState>,
    axum::Extension(auth_user): axum::Extension<AuthUser>,
    Path(nodo_id): Path<Uuid>,
    Json(payload): Json<CreateReunionDto>,
) -> (StatusCode, Json<ReunionResponse>) {
    // 1. Validar pertenencia al nodo
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
            Json(ReunionResponse {
                success: false,
                message: "No tienes permiso para programar reuniones en este nodo.".to_string(),
                reunion: None,
                reuniones: None,
            }),
        );
    }

    let titulo = payload.titulo.trim();
    if titulo.is_empty() {
        return (
            StatusCode::BAD_REQUEST,
            Json(ReunionResponse {
                success: false,
                message: "El título de la reunión no puede estar vacío.".to_string(),
                reunion: None,
                reuniones: None,
            }),
        );
    }

    let result = sqlx::query_as::<_, (Uuid, Uuid, String, Option<String>, DateTime<Utc>, Option<DateTime<Utc>>, Option<String>, Uuid, DateTime<Utc>)>(
        "INSERT INTO reuniones (nodo_id, titulo, descripcion, fecha_inicio, fecha_fin, enlace_reunion, creado_por) 
         VALUES ($1, $2, $3, $4, $5, $6, $7) 
         RETURNING id, nodo_id, titulo, descripcion, fecha_inicio, fecha_fin, enlace_reunion, creado_por, created_at"
    )
    .bind(nodo_id)
    .bind(titulo)
    .bind(&payload.descripcion)
    .bind(payload.fecha_inicio)
    .bind(payload.fecha_fin)
    .bind(&payload.enlace_reunion)
    .bind(auth_user.user_id)
    .fetch_one(&state.pool)
    .await;

    match result {
        Ok((id, n_id, tit, desc, f_ini, f_fin, enlace, creador, created_at)) => {
            let creador_nombre = sqlx::query_scalar::<_, String>(
                "SELECT name FROM users WHERE id = $1"
            )
            .bind(creador)
            .fetch_one(&state.pool)
            .await
            .unwrap_or_else(|_| "Usuario".to_string());

            (
                StatusCode::CREATED,
                Json(ReunionResponse {
                    success: true,
                    message: "Reunión programada exitosamente.".to_string(),
                    reunion: Some(ReunionInfo {
                        id,
                        nodo_id: n_id,
                        titulo: tit,
                        descripcion: desc,
                        fecha_inicio: f_ini,
                        fecha_fin: f_fin,
                        enlace_reunion: enlace,
                        creado_por: creador,
                        creador_nombre,
                        created_at,
                    }),
                    reuniones: None,
                }),
            )
        }
        Err(e) => {
            eprintln!("Error al programar reunión: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ReunionResponse {
                    success: false,
                    message: "Error interno al programar la reunión.".to_string(),
                    reunion: None,
                    reuniones: None,
                }),
            )
        }
    }
}

// ─── GET /nodos/{id}/reuniones ───────────────────────────────────────────

pub async fn list_reuniones(
    State(state): State<AppState>,
    axum::Extension(auth_user): axum::Extension<AuthUser>,
    Path(nodo_id): Path<Uuid>,
) -> (StatusCode, Json<ReunionResponse>) {
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
            Json(ReunionResponse {
                success: false,
                message: "No perteneces a este nodo.".to_string(),
                reunion: None,
                reuniones: None,
            }),
        );
    }

    let rows = sqlx::query_as::<_, (Uuid, Uuid, String, Option<String>, DateTime<Utc>, Option<DateTime<Utc>>, Option<String>, Uuid, String, DateTime<Utc>)>(
        "SELECT r.id, r.nodo_id, r.titulo, r.descripcion, r.fecha_inicio, r.fecha_fin, r.enlace_reunion, r.creado_por, u.name, r.created_at
         FROM reuniones r
         JOIN users u ON r.creado_por = u.id
         WHERE r.nodo_id = $1
         ORDER BY r.fecha_inicio ASC"
    )
    .bind(nodo_id)
    .fetch_all(&state.pool)
    .await;

    match rows {
        Ok(list) => {
            let reuniones = list
                .into_iter()
                .map(|(id, n_id, tit, desc, f_ini, f_fin, enlace, creador, creador_nom, created_at)| ReunionInfo {
                    id,
                    nodo_id: n_id,
                    titulo: tit,
                    descripcion: desc,
                    fecha_inicio: f_ini,
                    fecha_fin: f_fin,
                    enlace_reunion: enlace,
                    creado_por: creador,
                    creador_nombre: creador_nom,
                    created_at,
                })
                .collect();

            (
                StatusCode::OK,
                Json(ReunionResponse {
                    success: true,
                    message: "Reuniones listadas exitosamente.".to_string(),
                    reunion: None,
                    reuniones: Some(reuniones),
                }),
            )
        }
        Err(e) => {
            eprintln!("Error al listar reuniones: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ReunionResponse {
                    success: false,
                    message: "Error interno al cargar las reuniones.".to_string(),
                    reunion: None,
                    reuniones: None,
                }),
            )
        }
    }
}

// ─── PUT /nodos/{id}/reuniones/{reunion_id} ─────────────────────────────

pub async fn update_reunion(
    State(state): State<AppState>,
    axum::Extension(auth_user): axum::Extension<AuthUser>,
    Path((nodo_id, reunion_id)): Path<(Uuid, Uuid)>,
    Json(payload): Json<UpdateReunionDto>,
) -> (StatusCode, Json<ReunionResponse>) {
    // 1. Validar que sea creador o ADMIN/OWNER
    let is_creator_or_admin = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS(
            SELECT 1 FROM reuniones r 
            LEFT JOIN nodo_miembros nm ON nm.nodo_id = r.nodo_id AND nm.user_id = $2
            WHERE r.id = $1 AND (r.creado_por = $2 OR nm.rol IN ('ADMIN', 'OWNER'))
        )"
    )
    .bind(reunion_id)
    .bind(auth_user.user_id)
    .fetch_one(&state.pool)
    .await
    .unwrap_or(false);

    if !is_creator_or_admin {
        return (
            StatusCode::FORBIDDEN,
            Json(ReunionResponse {
                success: false,
                message: "No tienes permiso para modificar esta reunión.".to_string(),
                reunion: None,
                reuniones: None,
            }),
        );
    }

    let result = sqlx::query(
        "UPDATE reuniones 
         SET titulo = COALESCE($1, titulo),
             descripcion = COALESCE($2, descripcion),
             fecha_inicio = COALESCE($3, fecha_inicio),
             fecha_fin = COALESCE($4, fecha_fin),
             enlace_reunion = COALESCE($5, enlace_reunion)
         WHERE id = $6 AND nodo_id = $7"
    )
    .bind(&payload.titulo)
    .bind(&payload.descripcion)
    .bind(payload.fecha_inicio)
    .bind(payload.fecha_fin)
    .bind(&payload.enlace_reunion)
    .bind(reunion_id)
    .bind(nodo_id)
    .execute(&state.pool)
    .await;

    match result {
        Ok(r) => {
            if r.rows_affected() == 0 {
                (
                    StatusCode::NOT_FOUND,
                    Json(ReunionResponse {
                        success: false,
                        message: "Reunión no encontrada.".to_string(),
                        reunion: None,
                        reuniones: None,
                    }),
                )
            } else {
                (
                    StatusCode::OK,
                    Json(ReunionResponse {
                        success: true,
                        message: "Reunión actualizada exitosamente.".to_string(),
                        reunion: None,
                        reuniones: None,
                    }),
                )
            }
        }
        Err(e) => {
            eprintln!("Error al actualizar reunión: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ReunionResponse {
                    success: false,
                    message: "Error interno al actualizar la reunión.".to_string(),
                    reunion: None,
                    reuniones: None,
                }),
            )
        }
    }
}

// ─── DELETE /nodos/{id}/reuniones/{reunion_id} ──────────────────────────

pub async fn delete_reunion(
    State(state): State<AppState>,
    axum::Extension(auth_user): axum::Extension<AuthUser>,
    Path((nodo_id, reunion_id)): Path<(Uuid, Uuid)>,
) -> (StatusCode, Json<ReunionResponse>) {
    let is_creator_or_admin = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS(
            SELECT 1 FROM reuniones r 
            LEFT JOIN nodo_miembros nm ON nm.nodo_id = r.nodo_id AND nm.user_id = $2
            WHERE r.id = $1 AND (r.creado_por = $2 OR nm.rol IN ('ADMIN', 'OWNER'))
        )"
    )
    .bind(reunion_id)
    .bind(auth_user.user_id)
    .fetch_one(&state.pool)
    .await
    .unwrap_or(false);

    if !is_creator_or_admin {
        return (
            StatusCode::FORBIDDEN,
            Json(ReunionResponse {
                success: false,
                message: "No tienes permiso para cancelar esta reunión.".to_string(),
                reunion: None,
                reuniones: None,
            }),
        );
    }

    let result = sqlx::query(
        "DELETE FROM reuniones WHERE id = $1 AND nodo_id = $2"
    )
    .bind(reunion_id)
    .bind(nodo_id)
    .execute(&state.pool)
    .await;

    match result {
        Ok(r) => {
            if r.rows_affected() == 0 {
                (
                    StatusCode::NOT_FOUND,
                    Json(ReunionResponse {
                        success: false,
                        message: "Reunión no encontrada.".to_string(),
                        reunion: None,
                        reuniones: None,
                    }),
                )
            } else {
                (
                    StatusCode::OK,
                    Json(ReunionResponse {
                        success: true,
                        message: "Reunión cancelada exitosamente.".to_string(),
                        reunion: None,
                        reuniones: None,
                    }),
                )
            }
        }
        Err(e) => {
            eprintln!("Error al eliminar reunión: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ReunionResponse {
                    success: false,
                    message: "Error interno al cancelar la reunión.".to_string(),
                    reunion: None,
                    reuniones: None,
                }),
            )
        }
    }
}
